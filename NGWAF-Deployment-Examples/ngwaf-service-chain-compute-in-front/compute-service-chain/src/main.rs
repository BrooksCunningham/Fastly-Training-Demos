// use fastly::http::StatusCode;
use fastly::{Error, Request, Response};

#[fastly::main]
fn main(req: Request) -> Result<Response, Error> {
    // Log service version
    println!(
        "FASTLY_SERVICE_VERSION: {}",
        std::env::var("FASTLY_SERVICE_VERSION").unwrap_or_else(|_| String::new())
    );
    
    let beresp = req.send("compute_origin_0")?;

    // return Ok(Response::from_body("Hello From C@E\n")
    //         .with_status(StatusCode::OK))
    return Ok(beresp)
}
