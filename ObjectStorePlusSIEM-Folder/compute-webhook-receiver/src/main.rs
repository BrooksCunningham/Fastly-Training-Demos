use fastly::http::{StatusCode, Method};
use fastly::{Error, Request, Response, ObjectStore};
use std::time::SystemTime;


#[fastly::main]
fn main(req: Request) -> Result<Response, Error> {
    if let Ok(fastly_service_version) = std::env::var("FASTLY_SERVICE_VERSION") {
        println!("FASTLY_SERVICE_VERSION: {}", fastly_service_version);
    }
    
    if req.get_method() == &Method::POST && req.get_path() == "/signal-sciences/webhook" {
        println!("[DEBUG], /signal-sciences/webhook");
        // Process the request and send the security check request
        let resp = process_json_webhook(req)?;
        return Ok(resp)
    }

    Ok(Response::from_status(StatusCode::OK))
}

fn process_json_webhook(mut req: Request) -> Result<Response, Error> {
    // Get body as a string from the request
    let body_string = req.take_body_str();

    let penalty_box_ip = ngwaf_webhook_json_handler(&body_string).unwrap();


    let store = "siem-store";
    let mut store = ObjectStore::open(&store).map(|store| store.expect("ObjectStore exists"))?;

    let now = format!("{}", SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap().as_secs());

    println!("[DEBUG], Adding to obj_store penalty_box_ip {}", &penalty_box_ip);
    store.insert(&penalty_box_ip, now)?;

    let entry = store.lookup(&penalty_box_ip)?;

    return match entry {
        // Stream the value back to the user-agent.
        Some(entry) => Ok(Response::from_body(entry)),
        None => Ok(Response::from_body("Entry not Found").with_status(404)),
    };
}

fn ngwaf_webhook_json_handler(input_data: &str) -> serde_json::Result<String> {

    // println!("{:?}", input_data);

    // Parse the string of data into serde_json::Value.
    let v: serde_json::Value = serde_json::from_str(input_data)?;
    
    // Access parts of the data by indexing with square brackets.
    // Testing JSON
    // curl 'https://sensibly-ace-elephant.edgecompute.app/signal-sciences/webhook' --data-raw '{"created":"2021-06-07T18:48:37.866007528Z","payload":{"action":"flagged", "source": "169.254.100.1"}}'
    // curl 'http://127.0.0.1:7676/signal-sciences/webhook' --data-raw '{"created":"2021-06-07T18:48:37.866007528Z","payload":{"action":"flagged", "source": "169.254.1.1"}}'
    // curl 'https://sensibly-ace-elephant.edgecompute.app/signal-sciences/webhook' --data-raw '{"created":"2021-06-08T14:05:24.505563292Z","type":"","payload":{"message":"Congratulations, you successfully set up your generic integration within Signal Sciences"}}'

    // if not null
    if !v["payload"]["source"].is_null() {
        // println!("[DEBUG], source hit");
        let str_ip = v["payload"]["source"].as_str().unwrap();
        Ok(str_ip.to_string())
    } // if not null
    else if !v["payload"]["message"].is_null() {
        println!("[DEBUG], JSON msg hit");
        Ok("169.254.200.200".to_string())
    } 
    else {
        Ok("169.254.211.211".to_string())
    }
}