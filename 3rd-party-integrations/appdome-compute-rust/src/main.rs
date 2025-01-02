use boring::reexports::rsa::pkcs8::der::Header;
use fastly::security::{inspect, InspectConfig, InspectError, InspectResponse};
use fastly::handle::BodyHandle;
use fastly::{Error, Request, Response};

use fastly::http::{HeaderValue, StatusCode};

use boring;
use hex;
use sha2::{Digest, Sha256};
use base64::prelude::*;

#[fastly::main]
fn main(mut req: Request) -> Result<Response, Error> {
    // Log service version
    println!(
        "FASTLY_SERVICE_VERSION: {}",
        std::env::var("FASTLY_SERVICE_VERSION").unwrap_or_else(|_| String::new())
    );

    // Do not cache requests
    req.set_pass(true);

    let req = appdome_inspect(req)?;

    // Returns req to allow for setting request headers based on the WAF inspection.
    let (mut req, waf_inspection_result) = do_waf_inspect(req);

    Ok(Response::from_status(StatusCode::OK).with_body("hello from compute"))
}

fn appdome_inspect(req: Request) -> Result<Request, Error> {
    let (mut req, appdome_headers) = get_appdome_headers(req);

    println!("{:?}", appdome_headers);

    // TODO, These values should be stored in a config store or secret store
    let protected_secret = "good";
    let compromised_secret = "bad";

    let signed_message = hex::decode(appdome_headers.signed_message)?;
    let nonce = appdome_headers.nonce;
    let timestamp = appdome_headers.timestamp;
    let metadata = appdome_headers.metadata;
    let threatid = hex::decode(appdome_headers.threatid)?;
    let valid = format!("{}_{}_{}", timestamp, nonce, protected_secret);

    let timestamp_u64: u64 = timestamp.parse().unwrap_or(0);
    let timestamp_compare_result = compare_epoch(timestamp_u64);

    println!("DEBUG, timestamp_compare_result, {}", &timestamp_compare_result);

    println!("DEBUG, valid, {}", &valid);
    let compromised = format!("{}_{}_{}", timestamp, nonce, compromised_secret);
    println!("DEBUG, compromised, {}", &compromised);

    let decrypted_threatid = decrypt(&threatid).unwrap_or("".to_string());

    let decrypted_threatid_bytes = hex::decode(&decrypted_threatid)?;

    let threatid_base64 = std::str::from_utf8(&decrypted_threatid_bytes)?;
    // println!("DEBUG, threatid_str, {}", &threatid_str);
    // let threatid_base64 = BASE64_STANDARD.encode(&threatid_str);
    // println!("DEBUG, threatid_base64, {}", &threatid_base64);
    // TODO. Add error handling
    let appdome_threatid = String::from_utf8(BASE64_STANDARD.decode(&threatid_base64)?)?;
    println!("DEBUG, appdome_threatid, {}", appdome_threatid);
    println!("DEBUG, metadata, {}", &metadata);

    let decrypted_signed_message = decrypt(&signed_message).unwrap_or("".to_string());

    println!(
        "DEBUG, decrypted_signed_message, {}",
        decrypted_signed_message
    );

    let valid_hash_result = sha256hash(valid);
    let compromised_hash_result = sha256hash(compromised);

    // check timestamp in epoch
    println!("DEBUG, valid_hash_result, {}", &valid_hash_result);
    println!(
        "DEBUG, compromised_hash_result, {}",
        &compromised_hash_result
    );

    if decrypted_signed_message == valid_hash_result {
        println!("DEBUG, valid_hash_result_match");
    };

    if decrypted_signed_message == compromised_hash_result {
        println!("DEBUG, compromised_hash_result_match");
    };


    let appdome_threatid_headervalue = HeaderValue::from_str(&appdome_threatid)
    .unwrap_or(HeaderValue::from_static("no_threats"));

    req.set_header("appdome-threatid", appdome_threatid_headervalue);

    return Ok(req);
}

// Define a struct to hold the header values
#[derive(Debug)]
struct AppdomeHeaders {
    threatid: String,
    metadata: String,
    timestamp: String,
    nonce: String,
    signed_message: String,
}

fn get_appdome_headers(req: Request) -> (Request, AppdomeHeaders) {
    let threatid = req.get_header_str("threatid").unwrap_or("").to_owned();
    let metadata = req.get_header_str("metadata").unwrap_or("").to_owned();
    let timestamp = req.get_header_str("timestamp").unwrap_or("").to_owned();
    let nonce = req.get_header_str("nonce").unwrap_or("").to_owned();
    let signed_message = req.get_header_str("signedMessage").unwrap_or("").to_owned();

    // Return an instance of AppdomeHeaders with the extracted values
    return (
        req,
        AppdomeHeaders {
            threatid,
            metadata,
            timestamp,
            nonce,
            signed_message,
        },
    );
}

fn decrypt(ciphertext: &[u8]) -> Result<String, Box<dyn std::error::Error>> {
    // Unencrypted RSA private key in PEM format
    let rsa_pem = include_str!("sessionprivatekey.pem");

    // Import the RSA private key
    let rsa_key = boring::rsa::Rsa::private_key_from_pem(rsa_pem.as_bytes())?;

    // Decrypt the ciphertext
    let mut plaintext = vec![0; ciphertext.len()];
    let plaintext_len =
        rsa_key.private_decrypt(ciphertext, &mut plaintext, boring::rsa::Padding::PKCS1)?;
    let plaintext = &plaintext[..plaintext_len];

    let hex = hex::encode(&plaintext);

    return Ok(hex);
}

fn sha256hash(input: String) -> String {
    // create a Sha256 object
    let mut hasher = Sha256::new();

    // write input message for hash
    hasher.update(input);

    // read hash digest and consume hasher
    let valid_hash_result = hasher.finalize();

    let hash_hex = hex::encode(&valid_hash_result);

    return hash_hex;
}

fn do_waf_inspect(mut req: Request) -> (Request, Response) {
    // if bypass-waf is present, then do not send the request to the WAF for processing
    match req.get_header_str("bypass-waf") {
        Some(_) => {
            println!("bypassing waf");
            return (
                req,
                Response::from_status(StatusCode::OK).with_set_header(
                    "x-version",
                    std::env::var("FASTLY_SERVICE_VERSION").unwrap_or_else(|_| String::new()),
                ),
            );
        }
        _ => {
            let ngwaf_config = fastly::config_store::ConfigStore::open("ngwaf");
            let corp_name = ngwaf_config
                .get("corp")
                .expect("no `corp` present in config");
            let site_name = ngwaf_config
                .get("site")
                .expect("no `site` present in config");

            // clone the request and send the cloned request to the waf inspection.
            let inspection_req = req.clone_with_body();
            let (reqhandle, bodyhandle) = inspection_req.into_handles();
            let bodyhandle = bodyhandle.unwrap_or_else(|| BodyHandle::new());

            let inspectconf: InspectConfig<'_> = InspectConfig::new(&reqhandle, &bodyhandle)
                .corp(&corp_name)
                .workspace(&site_name);
            let waf_result: Result<InspectResponse, InspectError> = inspect(inspectconf);

            match waf_result {
                Ok(x) => {
                    // Handling WAF result
                    println!(
                    "waf_response_code: {}\nwaf_tags: {:?}\nwaf_decision_ms: {:?}\nwaf_verdict: {:?}",
                    x.status(),
                    x.tags(),
                    x.decision_ms(),
                    x.verdict(),
                    );
                    req.set_header(
                        "waf-response",
                        HeaderValue::from_str(&x.status().to_string()).unwrap(),
                    );
                    req.set_header(
                        "waf-tags",
                        HeaderValue::from_str(
                            x.tags()
                                .into_iter()
                                .collect::<Vec<&str>>()
                                .join(", ")
                                .as_str(),
                        )
                        .unwrap(),
                    );
                    req.set_header(
                        "waf-decision-ms",
                        HeaderValue::from_str(format!("{:?}", &x.decision_ms()).as_str()).unwrap(),
                    );
                    req.set_header(
                        "waf-verdict",
                        HeaderValue::from_str(format!("{:?}", &x.verdict()).as_str()).unwrap(),
                    );
                }
                Err(y) => match y {
                    InspectError::InvalidConfig => {
                        println!("NGWAF failed because of invalid configuration");
                        return (
                            req,
                            Response::from_status(StatusCode::SERVICE_UNAVAILABLE).with_set_header(
                                "x-version",
                                std::env::var("FASTLY_SERVICE_VERSION")
                                    .unwrap_or_else(|_| String::new()),
                            ),
                        );
                    }
                    InspectError::RequestError(f) => {
                        println!(
                    "Failed to send an inspection request to the NGWAF FastlyStatusCode: {}",
                    f.code
                );
                        return (
                            req,
                            Response::from_status(StatusCode::SERVICE_UNAVAILABLE).with_set_header(
                                "x-version",
                                std::env::var("FASTLY_SERVICE_VERSION")
                                    .unwrap_or_else(|_| String::new()),
                            ),
                        );
                    }
                    _ => println!("Catch-all waf_result"),
                },
            };

            return (
                req,
                Response::from_status(StatusCode::OK).with_set_header(
                    "x-version",
                    std::env::var("FASTLY_SERVICE_VERSION").unwrap_or_else(|_| String::new()),
                ),
            );
        }
    }
}

fn compare_epoch(given_epoch: u64) -> bool{
    // use chrono::{DateTime, NaiveDateTime, Utc};
    use std::time::{SystemTime, UNIX_EPOCH};

    // Get the current epoch time
    let start = SystemTime::now();
    let since_the_epoch = start.duration_since(UNIX_EPOCH)
        .expect("Time went backwards");
    let current_epoch = since_the_epoch.as_secs();

    // Check if date_epoch is less than 30 minutes in the past
    let thirty_minutes = current_epoch - (30 * 60);
    if thirty_minutes < given_epoch {
        println!("The given date is less than 30 minutes in the past.");
        return true
    }
    println!("The given date is not less than 30 minutes in the past.");
    return false
        
}