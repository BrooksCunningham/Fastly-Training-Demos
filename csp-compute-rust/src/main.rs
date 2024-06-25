//! Default Compute template program.

use fastly::http::{header, Method, StatusCode};
use fastly::{mime, ConfigStore, Error, Request, Response};
use serde_json::json;

/// The entry point for your application.
///
/// This function is triggered when your service receives a client request. It could be used to
/// route based on the request properties (such as method or path), send the request to a backend,
/// make completely new requests, and/or generate synthetic responses.
///
/// If `main` returns an error, a 500 error response will be delivered to the client.

#[fastly::main]
fn main(mut req: Request) -> Result<Response, Error> {
    // Log service version
    println!(
        "FASTLY_SERVICE_VERSION: {}",
        std::env::var("FASTLY_SERVICE_VERSION").unwrap_or_else(|_| String::new())
    );

    let csp_config_store = ConfigStore::open("csp");

    // Pattern match on the path...
    println!("{:?}", req.get_path());
    match req.get_path() {
        // If request is to the `/` path...
        "/" => {
            // println!("{:?}", req.get_path());

            println!(
                "{}",
                csp_config_store.get("mode").unwrap_or("foo".to_string())
            );

            
            // Use either the blocking header or the reporting header
            let csp_header_name = match csp_config_store.get("mode"){
                Some(val) if val == "blocking" => "Content-Security-Policy",
                _ => "Content-Security-Policy-Report-Only",
            };

            Ok(Response::from_status(StatusCode::OK)
                .with_content_type(mime::TEXT_HTML_UTF_8)
                .with_header(csp_header_name, "script-src 'self'; object-src 'none'; report-to main-endpoint;")
                .with_header("Reporting-Endpoints", r#"main-endpoint="https://csp-reports.edgecompute.app/csp-main-endpoint", default="https://csp-reports.edgecompute.app/default""#)
                .with_body(include_str!("welcome-to-compute.html")))
        }

        "/csp-main-endpoint" => {
            // let body = req.take_body_str();
            let body = req.take_body_json().unwrap_or(json!({}));
            println!("{}", &body);
            Ok(Response::from_status(StatusCode::OK))
        }

        // Catch all other requests and return a 404.
        _ => {
            // println!("{:?}", req.get_path());
            Ok(Response::from_status(StatusCode::OK))
        }
    }
}
