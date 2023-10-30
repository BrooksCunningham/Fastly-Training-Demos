use fastly::handle::client_request_id;
use fastly::http::StatusCode;
use fastly::{ConfigStore, Error, Request, Response};
// use fastly::handle::client_ip_addr;
use serde_json::json;
use serde_json::Value;
use base64::encode;
// use Engine::encode;

#[fastly::main]
fn main(mut req: Request) -> Result<Response, Error> {
    // make a copy of the req
    let mut req_cloned: Request = req.clone_with_body();

    

    // Ok(Response::from_status(StatusCode::OK))
    let mut resp: Response = req.send("origin")?;
    // let mut resp: Response = Response::new();
    // resp.set_status(StatusCode::OK);
    // let _ = resp.set_body_json(&formatted_data);

    let mut resp_cloned: Response = resp.clone_with_body();
    
    let _ = println!("{:?}", send_to_har(req_cloned, resp_cloned));
    Ok(resp)
}
fn send_to_har(mut req: Request, mut resp: Response) -> Result<&'static str, Error> {
    // Get request method
    let req_method: String = req.get_method_str().to_owned();

    // Get request headers
    let mut req_headers_data: Value = serde_json::json!({});
    for (n, v) in req.get_headers() {
        let req_header_name_str: &str = n.as_str();
        let req_header_val_str: &str = v.to_str()?;
        req_headers_data[req_header_name_str] = json!(req_header_val_str);
    }

    // Get url
    let req_url: fastly::http::Url = req.get_url().to_owned();

    // Take the body of the request.
    // let req_body: String = encode(req.take_body_str_lossy());
    let req_body: String = encode(req.take_body_bytes());

    // Get host header
    let host_str: &str = req_url.host_str().ok_or("").unwrap();

    // Generate a request
    let request_id: &str = client_request_id().ok_or("noId").unwrap();

    // let client_ip_addr = client_ip_addr().unwrap().to_string();

    // Get the response data
    // Get request headers
    let mut resp_headers_data: Value = serde_json::json!({});
    for (n, v) in req.get_headers() {
        let resp_header_name_str: &str = n.as_str();
        let resp_header_val_str: &str = v.to_str()?;
        resp_headers_data[resp_header_name_str] = json!(resp_header_val_str);
    }
    let resp_body: String = encode(resp.take_body_bytes());
    
    /*
    let mut formatted_data: Value = serde_json::json!({
      "requestID": &request_id,
      "scheme": "http",
      "destinationAddress": "127.0.0.1:80",
      "destinationNamespace": "DESTNAMESPACEPLACEHOLDER",
      "sourceAddress": "127.0.0.1:80",
      "request": {
        "method": &req_method,
        "path": &req_url.as_str(),
        "host": &host_str,
        "common": {
          "version": "1",
          "headers": [
              &req_headers_data
          ],
          "body": &req_body,
          "TruncatedBody": false
        }
      },
      "response": {
        "statusCode": resp.get_status().as_u16().to_string(),
        "common": {
          "version": "1",
          "headers": &resp_headers_data,
          "headers": [
            &resp_headers_data
          ],
          "body": &resp_body,
          "TruncatedBody": false
        }
      }
    });
    */

    let mut har_formatted_data: Value = serde_json::json!({
      "log": {
        "version": "1.2",
        "creator": {
          "name": "WebInspector",
          "version": "537.36"
        },
        "pages": [],
        "entries": [
          {
            "request": {
              "method": &req_method,
              "url": &req_url.as_str(),
              "httpVersion": "http/2.0",
              "headers": [
                &req_headers_data
              ],
              "queryString": [],
              "cookies": [],
              "headersSize": -1,
              "bodySize": 0
            },
            "response": {
              "status": resp.get_status().as_u16().to_string(),
              "statusText": "Found",
              "httpVersion": "http/2.0",
              "headers": [
                &resp_headers_data
              ],
              "cookies": [],
              "content": {
                "size": 0,
                "mimeType": "x-unknown",
                "text": ""
              },
              "redirectURL": "",
              "headersSize": -1,
              "bodySize": -1,
            },
            "serverIPAddress": "127.0.0.1",
            "startedDateTime": "2023-10-30T00:00:00.000Z",
            "time": 0,
            "timings": {
              "blocked": 0,
              "dns": 0,
              "ssl": 0,
              "connect": 0,
              "send": 0,
              "wait": 0,
              "receive": 0
            }
          }
        ]
      }
    });

    println!("{}", &har_formatted_data);
    // println!("{}", &formatted_data);
    // println!();


    return Ok("HAR HAR");
}
