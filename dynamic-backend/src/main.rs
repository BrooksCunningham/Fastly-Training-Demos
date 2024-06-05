use fastly::http::{header, StatusCode};
use fastly::{Backend, Error, Request, Response};
use serde;
use std::collections::HashMap;
use std::fmt::Debug;
use std::time::Duration;

#[fastly::main]
fn main(req: Request) -> Result<Response, Error> {
    let resp = match req.get_path() {
        "/static/domain_form.html" => static_response(include_bytes!("static/domain_form.html")),
        "/dynamic_backend/submit" => domain_cookie_response(req),
        _ => send_req_to_backend(req)?,
    };

    Ok(resp)
}

fn static_response(bytes: &[u8]) -> Response {
    Response::from_body(bytes)
        // Add a long cache header to the response.
        .with_header(header::CACHE_CONTROL, "public, max-age=86400")
        .with_content_type(fastly::mime::TEXT_HTML_UTF_8)
}

fn domain_cookie_response(mut req: Request) -> Response {
    #[derive(serde::Deserialize, Debug)]
    struct FormData {
        domain_name: String,
    }

    let submitted_form_data = req.take_body_form::<FormData>().unwrap();
    println!("{}", &submitted_form_data.domain_name);

    let new_url = "/";
    let cookie_value = format!(
        "fsly_domain={}; Max-Age=3600; Path=/; HttpOnly; SameSite=Lax",
        &submitted_form_data.domain_name
    );
    Response::from_status(StatusCode::TEMPORARY_REDIRECT)
        .with_header(header::LOCATION, new_url)
        .with_header(header::SET_COOKIE, cookie_value)
}

fn send_req_to_backend(req: Request) -> Result<Response, Error> {
    let target_host = match req.get_header_str("cookie") {
        Some(cookie) => {
            let cookies = parse_cookies(cookie);
            // let fsly_domain_value = cookies.get("fsly_domain").unwrap();

            let fsly_domain_value = match cookies.get("fsly_domain") {
                Some(cookie_value) => cookie_value,
                None => "http.edgecompute.app",
            };

            fsly_domain_value.to_string()
        }
        // _ => "http.edgecompute.app".to_string()
        _ => return Ok(static_response(include_bytes!("static/domain_form.html"))),
    };

    // let target_host_string = target_host.unwrap_or("http.edgecompute.app".to_string());

    // let backend = Backend::builder("my_backend", &target_host)
    let backend = Backend::builder(&target_host, &target_host)
        .override_host(&target_host)
        .connect_timeout(Duration::from_secs(1))
        .first_byte_timeout(Duration::from_secs(15))
        .between_bytes_timeout(Duration::from_secs(10))
        .enable_ssl()
        .sni_hostname(&target_host)
        .finish()?;

    let resp = req.send(backend)?;

    return Ok(resp);
}

/// Parses the Cookie header and returns a HashMap where each entry corresponds to a cookie.
fn parse_cookies(header_str: &str) -> HashMap<String, String> {
    let mut cookies = HashMap::new();
    // The Cookie header is typically a single string of key-value pairs separated by '; '
    if let cookies_str = header_str {
        for cookie in cookies_str.split(';').map(|s| s.trim()) {
            let mut parts = cookie.splitn(2, '=');
            if let (Some(name), Some(value)) = (parts.next(), parts.next()) {
                cookies.insert(name.to_string(), value.to_string());
            }
        }
    }
    cookies
}
