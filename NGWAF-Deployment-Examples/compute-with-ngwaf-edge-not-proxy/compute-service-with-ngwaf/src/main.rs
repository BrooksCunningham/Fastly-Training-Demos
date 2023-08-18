// use fastly::http::StatusCode;
use fastly::{Error, Request, Response};

// BACKEND_HTTPME
const BACKEND_HTTPME: &str = "httpme_origin";

// BACKEND_NGWAF
const BACKEND_NGWAF: &str = "ngwaf_origin";

#[fastly::main]
fn main(mut req: Request) -> Result<Response, Error> {

    // clone the request to send off for a WAF check
    let req_for_waf_check = req.clone_with_body();

    // return the WAF response
    let waf_response = waf_request_check(req_for_waf_check)?;

    req.set_header("host", "http-me.glitch.me");
    Ok(req.send(BACKEND_HTTPME)?)
}

fn waf_request_check(req: Request) -> Result<Response, Error> {

    let waf_req = req
        .send_async(BACKEND_NGWAF)?;

    let pending_reqs = vec![waf_req];

    let (waf_resp, _remaining) = fastly::http::request::select(pending_reqs);

    let waf_resp_resolved = waf_resp? ;

    println!("ngwaf-agentresponse: {:?}", waf_resp_resolved.get_header_str("ngwaf-agentresponse"));
    println!("ngwaf-decision-ms: {:?}", waf_resp_resolved.get_header_str("ngwaf-decision-ms"));
    println!("ngwaf-tags: {:?}", waf_resp_resolved.get_header_str("ngwaf-tags"));

    return Ok(waf_resp_resolved)
}

