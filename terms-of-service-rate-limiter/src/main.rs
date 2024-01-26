use core::fmt;

// use fastly::;
// use fastly::{http::request, Error, Request, Response};
use serde_json::json;

use {
    fastly::{
        // cache::core::{Transaction, CacheKey},
        cache::core::*,
        http::StatusCode,
        // mime,
        Body,
        ConfigStore,
        Error,
        Request,
        Response,
    },
    std::{
        io::{Read, Write},
        time::Duration,
    },
};

#[fastly::main]
fn main(mut req: Request) -> Result<Response, Error> {
    println!(
        "FASTLY_HOSTNAME, {}",
        std::env::var("FASTLY_HOSTNAME").unwrap_or_else(|_| String::new())
    );
    println!(
        "FASTLY_TRACE_ID, {}",
        std::env::var("FASTLY_TRACE_ID").unwrap_or_else(|_| String::new())
    );
    println!(
        "FASTLY_SERVICE_VERSION, {}",
        std::env::var("FASTLY_SERVICE_VERSION").unwrap_or_else(|_| String::new())
    );

    let tos_check_value = terms_of_service_rate_limiter_check(&req);
    println!("tos_check_value, {:?}", &tos_check_value);

    match &tos_check_value {
        true => Ok(
            Response::from_status(StatusCode::EXPECTATION_FAILED).with_body("rate_check, true ")
        ),
        _ => {
            req.set_header("host", "http-me.edgecompute.app");
            Ok(req.send("backend_httpme")?)
        }
    }
    // Ok(Response::from_status(StatusCode::OK))
}

fn terms_of_service_rate_limiter_check(req: &Request) -> bool {
    // println!("STEP, terms_of_service_rate_limiter_check");

    // Get entry value
    let rl_value = req.get_header_str("api-key").unwrap_or("");
    // println!("rl_value, {}", &rl_value);

    // Check entry in core-cache-api
    let cache_key: &[u8] = rl_value.as_bytes();

    // Handler for core-cache. Needed to handle exceptions from local testing
    let updated_core_cache_value = core_cache_handler(cache_key);
    // println!("updated_core_cache_value, {:?}", &updated_core_cache_value);

    // load the different product tiers and rates
    let customer_product_tier_name = req.get_header_str("product-tier").unwrap_or("free");
    let customer_product_tier_rate = get_product_tier_rate(&customer_product_tier_name);

    println!(
        "customer_product_tier_name {:?}, customer_product_tier_rate {:?}, updated_core_cache_value, {:?}",
        &customer_product_tier_name, &customer_product_tier_rate, &updated_core_cache_value
    );

    // Compare rate to allowed tier rate
    let rate_limit_comparison: bool = match &customer_product_tier_rate {
        cust_rate if &updated_core_cache_value > cust_rate => true,
        _ => false,
    };

    // return the boolean if true if rate is exceeded

    return rate_limit_comparison;
}

fn read_core_cache_value(cache_key: CacheKey) -> (Transaction, Body) {
    println!("cache_key lookup, {:?}", &cache_key);

    let lookup_tx = Transaction::lookup(cache_key).execute().unwrap();
    match lookup_tx.found() {
        Some(found) if found.is_stale() => {
            // a cached item was found; we use it now even though it might be stale,
            // println!("cache lookup, is_stale");
            return (lookup_tx, found.to_stream().expect("Should always be OK"));
        }
        Some(found) if found.is_usable() => {
            // a cached item was found; we use it now even though it might be stale,
            // println!("cache lookup, is_usable");
            return (lookup_tx, found.to_stream().expect("Should always be OK"));
        }
        _ => {
            // println!("cache lookup, default");
            return (lookup_tx, Body::new());
        }
    }
}

fn update_core_cache_value(contents: [u8; 4], lookup_tx: Transaction, surrogate_keys: [&str; 1]) {
    let contents: [u8; 4] = contents;
    let ttl: Duration = Duration::from_secs(0);
    let stale_while_revalidation: Duration = Duration::from_secs(600);
    match lookup_tx.must_insert_or_update() {
        true => {
            let (mut writer, _found) = lookup_tx
                .insert(ttl)
                .stale_while_revalidate(stale_while_revalidation)
                .surrogate_keys(surrogate_keys)
                .known_length(contents.len() as u64)
                // stream back the object so we can use it after inserting
                .execute_and_stream_back()
                .unwrap();
            writer.write_all(&contents).unwrap();
            writer.finish().unwrap();
            // println!("Inserted value to cache")
        }
        _ => println!("Did not insert for some reason... Weird."),
    }
}

fn get_product_tier_rate(product_tier: &str) -> i32 {
    return match ConfigStore::open("product_tiers_rate").get(product_tier) {
        Some(rate_value) => rate_value.parse::<i32>().unwrap_or(999999),
        None => 999999,
    };
}

fn core_cache_handler(cache_key: &[u8]) -> i32 {
    let (lookup_tx, core_cache_value) =
        read_core_cache_value(CacheKey::copy_from_slice(&cache_key));

    let parsed_core_cache_value: i32 = i32::from_be_bytes(
        core_cache_value
            .into_bytes()
            .try_into()
            .unwrap_or([0, 0, 0, 0]),
    );
    println!("parsed_core_cache_value, {:?}", &parsed_core_cache_value);

    // Increment entry in core-cache-api
    let updated_core_cache_value = 1 + &parsed_core_cache_value;
    // Do anything you want with the updated value.
    update_core_cache_value(
        updated_core_cache_value.to_be_bytes(),
        lookup_tx,
        ["my_surragate_key"],
    );
    // println!("core_cache_handler");
    return updated_core_cache_value;
}
