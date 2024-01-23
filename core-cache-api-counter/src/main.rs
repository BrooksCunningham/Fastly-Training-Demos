// use std::io::Bytes;

use {
    fastly::{
        // cache::core::{Transaction, CacheKey},
        cache::core::*,
        mime,
        Body,
        Error,
        Request,
        Response,
    },
    std::{io::Write, time::Duration},
};

#[fastly::main]
fn main(req: Request) -> Result<Response, Error> {
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

    // Attempt to get a cache key from the query param cache_key or just use a default key
    let cache_key: &[u8] = req.get_query_parameter("cache_key").unwrap_or("default_key").as_bytes();
    let (lookup_tx, core_cache_value) = read_core_cache_value(CacheKey::copy_from_slice(&cache_key));

    let parsed_core_cache_value = match core_cache_value {
        ccv => {
            let cached_int: i32 = i32::from_be_bytes(ccv.into_bytes().try_into().unwrap_or([0, 0, 0, 0]));
            cached_int
        },
        _ => 0,
        
    };

    let updated_core_cache_value: i32 = match req.get_query_parameter("delete_key") {
        delete_key if delete_key.is_some() => {
            delete_cache_key(lookup_tx, ["my_surragate_key"]);
            0
        },
        _ => {
            // let core_cache_value: String = core_cache_value.into_string();
            let value = 1 + parsed_core_cache_value;
            // Do anything you want with the updated value.
            // let update_string: String = format!("{}\n{}", &core_cache_string, req.get_path());
            update_core_cache_value(value.to_be_bytes(), lookup_tx, ["my_surragate_key"]);
            value
        },
    };

    // Create a new body that may be written into
    let mut resp_body: Body = Body::new();
    resp_body.write_str(&updated_core_cache_value.to_string());

    return Ok(Response::from_body(resp_body)
        .with_content_type(mime::TEXT_PLAIN_UTF_8)
        .with_status(200))

}

fn read_core_cache_value(cache_key: CacheKey) -> (Transaction, Body) {
    let lookup_tx = Transaction::lookup(cache_key).execute().unwrap();

    match lookup_tx.found() {
        Some(found) if found.is_stale() => {
            // a cached item was found; we use it now even though it might be stale,
            println!("cache lookup, is_stale");
            return (lookup_tx, found.to_stream().expect("Should always be OK"));
        }
        Some(found) if found.is_usable() => {
            // a cached item was found; we use it now even though it might be stale,
            println!("cache lookup, is_usable");
            return (lookup_tx, found.to_stream().expect("Should always be OK"));
        }
        _ => {
            println!("cache lookup, default");
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
            println!("Inserted value to cache");
        }
        _ => println!("Did not insert for some reason... Weird."),
    }
}

fn delete_cache_key(lookup_tx: Transaction, surrogate_keys: [&str; 1]) {
    let contents: &[u8] = "".as_bytes();
    let ttl: Duration = Duration::from_secs(0);
    let stale_while_revalidation: Duration = Duration::from_secs(0);
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
            writer.write_all(contents).unwrap();
            writer.finish().unwrap();
            println!("Cache key deleted")
        }
        _ => println!("Did not delete for some reason... Weird."),
    }
}