use fastly::http::StatusCode;
use fastly::{Error, Request, Response};
use serde::Deserialize;

#[fastly::main]
fn main(mut req: Request) -> Result<Response, Error> {
    // Only accept POST requests
    if req.get_method() != "POST" {
        return Ok(Response::from_status(StatusCode::METHOD_NOT_ALLOWED));
    }

    // Retrieve the body as a form post
    let body_form = req.take_body_form::<PostParams>()?;

    Ok(Response::from_body(format!("{}", body_form.text)))
}


// Example form body token=123&team_id=123&team_domain=foo&channel_id=123&channel_name=slackbots-testing&user_id=123&user_name=foo&command=httpme&text=flybynight&api_app_id=123&is_enterprise_install=false&response_url=abc&trigger_id=123
#[derive(Deserialize)]
struct PostParams {
    token: String,
    team_id: String,
    team_domain: String,
    channel_id: String,
    channel_name: String,
    user_id: String,
    user_name: String,
    command: String,
    text: String,
    api_app_id: String,
    is_enterprise_install: Option<bool>,
    response_url: Option<String>,
    trigger_id: Option<String>,
}
