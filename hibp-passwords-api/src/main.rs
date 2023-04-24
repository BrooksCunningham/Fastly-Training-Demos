use fastly::ObjectStore;
use fastly::{Error, Request, Response};

// BACKEND_HIBP_API
const BACKEND_HIBP_API: &str = "hibpapiorigin";

#[fastly::main]
fn main(mut req: Request) -> Result<Response, Error> {
    // Log out which version of the Fastly Service is responding to this request.
    // This is useful to know when debugging.
    if let Ok(fastly_service_version) = std::env::var("FASTLY_SERVICE_VERSION") {
        println!("FASTLY_SERVICE_VERSION: {}", fastly_service_version);
    }

    let uri_vec: Vec<&str> = req.get_path().split("/").collect();
    
    // Check if uri vec is greater than 2 before looking for at the "1" index.
    if uri_vec.len() > 2 {
        if uri_vec[1] == "range" {
            let hash_query = uri_vec[2];
            /*
                Construct an ObjectStore instance which is connected to the Object Store named `hibp-store`
                [Documentation for the ObjectStore open method can be found here](https://docs.rs/fastly/latest/fastly/struct.ObjectStore.html#method.open)
            */
            let store = "hibp-store";

            let mut store =
                ObjectStore::open(&store).map(|store| store.expect("ObjectStore exists"))?;
    
            println!("{:?}", &hash_query);

            // Requests should be structured like the following curl command `curl -i https://api.pwnedpasswords.com/range/00000`
            if hash_query.len() < 4 {
                let mut entry_resp = Response::from_body("try again with a request like /range/00000");
                return Ok(entry_resp);   
            }
                
            let mut entry_resp = match store.lookup(&hash_query)? {
                // Return the response if there is a match
                Some(entry) => Response::from_body(entry),

                // Return response from the origin and add the response to the object store.
                _ => { 
                    // Need to clone the original request, cloning the body is not necessary since we should only receive GET requests
                    let mut backend_hibp_api_req = req.clone_without_body();
                    backend_hibp_api_req.set_header("host", "api.pwnedpasswords.com");

                    // send request to the backend
                    let mut beresp = backend_hibp_api_req.send(BACKEND_HIBP_API)?;

                    let mut backend_hibp_api_resp = beresp.clone_with_body();
                    let mut resp_body = backend_hibp_api_resp.take_body();

                    store.insert(&hash_query, resp_body)?;                    
                    println!("Value stored in Object Store: {}", &hash_query);

                    beresp
                },
                // _ => Response::from_body("try again with a request like /range/00000"),
            };
    
            // Allows for compression hints
            entry_resp.set_header("x-compress-hint", "on");
    
            return Ok(entry_resp);        
        } 
    }

    return Ok(Response::from_body(format!("{}", "try again with a request like /range/00000")));
}