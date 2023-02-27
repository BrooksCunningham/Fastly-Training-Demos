use fastly::ObjectStore;
use fastly::{Error, Request, Response};


#[fastly::main]
fn main(req: Request) -> Result<Response, Error> {
    // Log out which version of the Fastly Service is responding to this request.
    // This is useful to know when debugging.
    if let Ok(fastly_service_version) = std::env::var("FASTLY_SERVICE_VERSION") {
        println!("FASTLY_SERVICE_VERSION: {}", fastly_service_version);
    }

    let store = "hibp-store";
        
    let path = req.get_path();

    let mut path_split = path.split("/");

    let uri_vec: Vec<&str> = path_split.collect();
    
    // Check if uri vec is greater than 2 before looking for at the "1" index.
    if uri_vec.len() > 2 {
        if uri_vec[1] == "range" {
            let hash_query = uri_vec[2];
            /*
                Construct an ObjectStore instance which is connected to the Object Store named `my-store`
                [Documentation for the ObjectStore open method can be found here](https://docs.rs/fastly/latest/fastly/struct.ObjectStore.html#method.open)
            */
            
            let mut store =
                ObjectStore::open(&store).map(|store| store.expect("ObjectStore exists"))?;
    
            println!("{:?}", &hash_query);

            if hash_query.len() < 4 {
                let mut entry_resp = Response::from_body("try again with a request like /range/00000");
                return Ok(entry_resp);   
            }
                
            let mut entry_resp = match store.lookup(&hash_query)? {
                // Return the response if there is a match
                Some(entry) => Response::from_body(entry),
                // Return a helpful message if there is no entry
                _ => Response::from_body("try again with a request like /range/00000"),
            };
    
            // Allows for compression hints
            entry_resp.set_header("x-compress-hint", "on");
    
            return Ok(entry_resp);        
        } 
    }

    return Ok(Response::from_body(format!("{}", "try again with a request like /range/00000")));
}