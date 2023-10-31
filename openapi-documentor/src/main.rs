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

    
    // Setting the host header necessary for the backend.
    req.set_header("host", "http-me.edgecompute.app");
    
    let mut resp: Response = req.send("origin")?;
    // let mut resp: Response = Response::new();
    // resp.set_status(StatusCode::OK);
    // let _ = resp.set_body_json(&formatted_data);

    let mut resp_cloned: Response = resp.clone_with_body();
    // println!("{:?}", send_to_apiclarity(req_cloned, resp_cloned));
    let _ = println!("{:?}", send_to_apiclarity(req_cloned, resp_cloned));
    Ok(resp)
}
fn send_to_apiclarity(mut req: Request, mut resp: Response) -> Result<&'static str, Error> {
    // Get request method
    let req_method: String = req.get_method_str().to_owned();

    // Get request headers
    let mut req_headers_vec: Vec<Value> = Vec::new();
    for (n, v) in req.get_headers() {
        let req_header_name_str: &str = n.as_str();
        let req_header_val_str: &str = v.to_str()?;
        let req_header_json: Value = json!({
          "key" : &req_header_name_str,
          "value" : &req_header_val_str
        });
        req_headers_vec.push(req_header_json);
    }


    // Get url
    let req_url: fastly::http::Url = req.get_url().to_owned();
    let req_url_path: &str = req_url.path();

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
    let mut resp_headers_vec: Vec<Value> = Vec::new();

    for (n, v) in resp.get_headers() {
        let resp_header_name_str: &str = n.as_str();
        let resp_header_val_str: &str = v.to_str()?;
        let resp_header_json: Value = json!({
          "key" : &resp_header_name_str,
          "value" : &resp_header_val_str
        });

        resp_headers_vec.push(resp_header_json);
    }
    
    let resp_body: String = encode(resp.take_body_bytes());

    let formatted_data: Value = serde_json::json!({
      "requestID": &request_id,
      "scheme": "http",
      "destinationAddress": "127.0.0.1:80",
      "destinationNamespace": "DESTNAMESPACEPLACEHOLDER",
      "sourceAddress": "127.0.0.1:80",
      "request": {
        "method": &req_method,
        "path": &req_url_path,
        "host": &host_str,
        "common": {
          "version": "1",
          "headers": &req_headers_vec,
          "body": &req_body,
          "TruncatedBody": false
        }
      },
      "response": {
        "statusCode": resp.get_status().as_u16().to_string(),
        "common": {
          "version": "1",
          "headers": &resp_headers_vec,
          "body": &resp_body,
          "TruncatedBody": false
        }
      }
    });

    // println!();
    println!("{}", &formatted_data);
    // println!();

    let apiclarity_configstore = ConfigStore::open("apiclarity_configstore");

    // Get the trace source token with the following command and place this in the file, apiclarity_config.json.
    // TRACE_SOURCE_TOKEN=$(curl --http1.1 --insecure -s -H 'Content-Type: application/json' -d '{"name":"apigee_gateway","type":"APIGEE_X"}' https://localhost:8443/api/control/traceSources|jq -r '.token')
    let trace_source_token = apiclarity_configstore.get("trace_source_token").ok_or("").unwrap();

    let apiclarity_url = "http://apiclarity.local/api/telemetry";
    let mut apiclarity_req = Request::post(apiclarity_url);
    apiclarity_req.set_header("X-Trace-Source-Token", &trace_source_token);
    apiclarity_req.set_header("Content-Type", "application/json");
    apiclarity_req.set_header("accept", "application/json");
    apiclarity_req.set_body(format!("{}", &formatted_data));


    let _ = apiclarity_req.send("apiclarity")?;
    // let mut apiclarity_resp: Response = apiclarity_req.send("apiclarity")?;
    // println!("{:?}", apiclarity_resp.get_status());
    // println!("{:?}", apiclarity_resp.take_body_str_lossy());

    // println!("{:?}", apiclarity_req.send("apiclarity")?);
    


    return Ok("Sent to APIClarity");
}
