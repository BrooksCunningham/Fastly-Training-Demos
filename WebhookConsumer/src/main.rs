use fastly::http::StatusCode;
use fastly::{Error, Request, Response};
use serde_json::json;
use serde_json;

fn ngwaf_webhook_json_handler(v: serde_json::Value) -> serde_json::Result<String> {
   
    // Access parts of the data by indexing with square brackets.
    // Test with curl requests like the following the which are formated in a similar way the NextGen WAF webhooks
    // curl 'http://127.0.0.1:7676/webhook/nextgen-waf' --data-raw '{"created":"2021-06-07T18:48:37.866007528Z","payload":{"action":"flagged", "source": "169.254.100.1"}}'
    // curl 'http://127.0.0.1:7676/webhook/nextgen-waf' --data-raw '{"created":"2021-06-07T18:48:37.866007528Z","payload":{"action":"flagged", "source": "169.254.1.1"}}'
    // curl 'http://127.0.0.1:7676/webhook/nextgen-waf' --data-raw '{"created":"2021-06-08T14:05:24.505563292Z","type":"","payload":{"message":"Congratulations, you successfully set up your generic integration within Signal Sciences"}}'

    // if not null
    if !v["payload"]["source"].is_null() {
        // println!("[DEBUG], source hit");
        let str_ip = v["payload"]["source"].as_str().unwrap();
        Ok(str_ip.to_string())
    } // if not null
    else if !v["payload"]["message"].is_null() {
        // println!("[DEBUG], message hit");
        Ok("null".to_string())
    } 
    else {
        Ok("null".to_string())
    }
}

// Process json webhook
fn process_json_webhook(mut req: Request) -> Result<serde_json::Value, Error> {

    let body_json = req.take_body_json::<serde_json::Value>().unwrap();

    let penalty_box_ip = ngwaf_webhook_json_handler(body_json).unwrap();

    let kv_json_entry = json!({
        "key": penalty_box_ip,
        "value": "block"
        });

    // println!("[DEBUG], kv_json_entry : {}", kv_json_entry.to_string());

    // Do something interesting
    // Update an edge dictionary
    // Update a NextGen WAF list
    // create an entry in Object Store


    // Return request 
    return Ok(kv_json_entry);
}



#[fastly::main]
fn main(mut req: Request) -> Result<Response, Error> {

    // Perform get for key at /anything. Add the key if it is found
    if req.get_path() == "/webhook/nextgen-waf" && req.get_method() == "POST" {
        println!("[DEBUG], POST /signal-sciences/webhook");
        // Process the request
        let kv_json_entry = process_json_webhook(req)?;
        println!("[DEBUG], kv_json_entry : {}", kv_json_entry.to_string());
    }

    Ok(Response::from_status(StatusCode::OK))
}
