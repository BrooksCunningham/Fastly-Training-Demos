use fastly::{Error, Request, Response};

/// Embed the contents of `myheadervalue.txt` into the binary at compile time.
static MY_HEADER_VALUE: &str = include_str!("myheadervalue.txt");

#[fastly::main]
fn main(req: Request) -> Result<Response, Error> {
    // We’ll send the request to the “backend_name” defined in your fastly.toml (or via the CLI).
    // Replace "backend_name" with the actual name of your configured backend.
    let backend_name = "backend_name";

    // Trim the value to remove any possible trailing newlines.
    let value = MY_HEADER_VALUE.trim();

    // Insert the new header and its value.
    let mut bereq = req;
    bereq.set_header("api-key", value);
    bereq.set_header("host", "http.edgecompute.app");

    // Send the request upstream and return the response as-is.
    let beresp = bereq.send(backend_name)?;
    Ok(beresp)
}
