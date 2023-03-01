use fastly::http::StatusCode;
use fastly::{Error, Request, Response, ObjectStore};

#[fastly::main]
fn main(req: Request) -> Result<Response, Error> {
    
    // return the response from the object store
    let store = "siem-store";
    let store = ObjectStore::open(&store).map(|store| store.expect("ObjectStore exists"))?;
    

    match (req.get_path(), req.get_query_str()) {
        (_, Some(query)) if query.len() > 2 => {

            // let query_str: &str = query;
            println!("{}", &query);
            let entry = store.lookup(&query)?;

            return match entry {
                // Stream the value back to the user-agent.
                Some(entry) => {

                    Ok(Response::from_body(entry))
                },
                None => Ok(Response::from_body("Entry checked: True\n").with_status(404)),
            };
        },
        _ => Ok(Response::from_body("Entry checked: False\n").with_status(404)),
    }
}
