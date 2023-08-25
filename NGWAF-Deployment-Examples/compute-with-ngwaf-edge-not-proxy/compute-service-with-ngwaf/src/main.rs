// use fastly::http::StatusCode;
use fastly::{Error, Request, Response};
use std::time::Instant;

// BACKEND_HTTPME
const BACKEND_HTTPME: &str = "httpme_origin";

// BACKEND_NGWAF
const BACKEND_NGWAF: &str = "ngwaf_origin";


#[fastly::main]
fn main(mut req: Request) -> Result<Response, Error> {

    println!("FASTLY_SERVICE_ID, {}", std::env::var("FASTLY_SERVICE_ID").unwrap_or_else(|_| String::new()));
    println!("FASTLY_SERVICE_VERSION, {}", std::env::var("FASTLY_SERVICE_VERSION").unwrap_or_else(|_| String::new()));

    // clone the request to send off for a WAF check
    let req_for_waf_check = req.clone_with_body();

    // benchmark the waf_response function
    let before = Instant::now();

    // return the WAF response
    let waf_response = waf_request_check(req_for_waf_check)?;
    
    println!("Elapsed time waf_request_check, {:.4?}", before.elapsed());

    req.set_header("host", "http-me.glitch.me");
    Ok(req.send(BACKEND_HTTPME)?)
}

fn waf_request_check(mut req: Request) -> Result<Response, Error> {

    // Set the always-block header so that NGWAF always immediately blocks the request
    // This avoids an extra network hop to NGWAF origin
    req.set_header("always-block", "1");

    // TODO
    // Preserve the original host header in another header

    // Set the necessary host header for the request to be processed by ngwaf
    req.set_header("host", "compute-with-ngwaf-edge-vcl.global.ssl.fastly.net");

    let waf_req = req
        .send_async(BACKEND_NGWAF)?;

    let pending_reqs = vec![waf_req];

    // benchmark the waf_response function
    let before = Instant::now();

    let (waf_resp, _remaining) = fastly::http::request::select(pending_reqs);
    
    // benchmark
    println!("Elapsed time select, {:.4?}", before.elapsed());

    let waf_resp_resolved = waf_resp? ;

    println!("ngwaf-agentresponse, {:?}", waf_resp_resolved.get_header_str("ngwaf-agentresponse"));
    println!("ngwaf-decision-ms, {:?}", waf_resp_resolved.get_header_str("ngwaf-decision-ms"));
    println!("ngwaf-tags, {:?}", waf_resp_resolved.get_header_str("ngwaf-tags"));

    return Ok(waf_resp_resolved)
}

