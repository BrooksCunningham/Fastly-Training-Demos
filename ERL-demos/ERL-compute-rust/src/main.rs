use std::time::{SystemTime, Duration};
use std::fmt;
use serde_json::{self, json};

use fastly::{
    erl::{Penaltybox, RateCounter, RateWindow, ERL}, http::StatusCode, mime::{self, JSON}, Error, Request, Response
};

#[fastly::main]
fn main(req: Request) -> Result<Response, Error> {
    let now = SystemTime::now();

    // Open the rate counter and penalty box.
    let rc = RateCounter::open("rc_1");
    let pb = Penaltybox::open("pb_1");

    // Open the Edge Rate Limiter based on the rate counter and penalty box.
    let limiter = ERL::open(rc, pb);
    
    let erl_entry = req.get_url_str();

    // Check if the request should be blocked and update the rate counter.
    let result = limiter.check_rate(
        erl_entry, // The client to rate limit.
        1,                            // The number of requests this execution counts as.
        RateWindow::OneSec,        // The time window to count requests within.
        10, // The maximum average calculated requests per second allowed within the rate window.
        Duration::from_secs(15 * 60), // The duration to block the client if the rate limit is exceeded.
    );

    let erl_time_1 = format!("{:?}", now.elapsed());

    let is_blocked: bool = match result {
        Ok(is_blocked) => is_blocked,
        Err(err) => {
            // Failed to check the rate. This is unlikely but it's up to you if you'd like to fail open or closed.
            eprintln!("Failed to check the rate: {:?}", err);
            false
        }
    };

    let rc_1_primitive: RateCounter = RateCounter::open("rc_1");
    let pb_1_primitive: Penaltybox = Penaltybox::open("pb_1");
    
    let rc_1_lookup_count: u32 = rc_1_primitive.lookup_count(erl_entry, fastly::erl::CounterDuration::SixtySecs)?;
    let pb_1_lookup: bool = pb_1_primitive.has(erl_entry)?;

    let erl_time_2 = format!("{:?}", now.elapsed());

    let rl_info: String = json!({"rc_1_lookup_count":rc_1_lookup_count, "pb_1_lookup": pb_1_lookup, "is_blocked": is_blocked, "erl_time_1":erl_time_1, "erl_time_2":erl_time_2}).to_string();
    println!("{}", rl_info);

    match is_blocked {
        true => {
            let my_data = json!({"msg":"You have sent too many requests recently. Try again later."});
            return Ok(Response::from_status(StatusCode::TOO_MANY_REQUESTS)
                .with_body_json(&my_data).unwrap())
        }
        _ => {
            let mut resp: Response = Response::new();
            resp.set_status(200);
            resp.set_content_type(mime::APPLICATION_JSON);
            resp.set_body(rl_info);
        
            return Ok(resp)
        }
    }
}