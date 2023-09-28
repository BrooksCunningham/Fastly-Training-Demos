use fastly::http::StatusCode;
use fastly::{Error, Request, Response};
use fastly::handle::client_request_id;
use serde_json::json;

#[fastly::main]
fn main(mut req: Request) -> Result<Response, Error> {
    // Get request method
    let req_method = req.get_method_str().to_owned();

    // Get request headers
    let mut reqHeadersData = serde_json::json!({});
    for (n, v) in req.get_headers() {
        let reqHeaderNameStr = n.as_str();
        let reqHeaderValStr = v.to_str()?;
        reqHeadersData[reqHeaderNameStr] = serde_json::json!(reqHeaderValStr);
    }
    // println!("Headers: {}", &reqHeadersData);

    // Get url
    let reqUrl = req.get_url().to_owned();

    // Take the body of the request.
    let body = req.take_body_str_lossy();

    let host_str = reqUrl.host_str().ok_or("").unwrap();
    let host_vec = host_str.split(".").collect::<Vec<&str>>();

    let path_segments: Vec<&str> = reqUrl.path_segments().ok_or_else(|| ["cannot be base"]).unwrap().collect();
    println!("{:?}", &path_segments);

    let requestId = client_request_id().ok_or("noId").unwrap();
    println!("{}", &requestId);


    let formatted_data = serde_json::json!({
        "info": {
            "_postman_id": "abc",
            "name": "New Collection name",
            "description": "my first description",
            "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
            "_exporter_id": "123"
        },
        "item": [{
            "name": &requestId,
            "request": {
                "method": &req_method,
                // "headers": &reqHeadersData,
                "headers": [],
                "body": { 
                    "mode": "raw",
                    "raw": &body 
                },
                "url": { 
                    "raw": &reqUrl.as_str(),
                    "protocol": "https", // Compute@Edge only runs on https
                    "host": &host_vec,
                    "path": &path_segments,
                },
            },
            "response" : [],
        }]
    });

    // println!("{}", &body);
    println!();
    println!("{}", &formatted_data);
    println!();

    // Ok(Response::from_status(StatusCode::OK))
    let mut resp = Response::new();
    resp.set_status(StatusCode::OK);
    resp.set_body_json(&formatted_data);
    Ok(resp)
}
