use std::ops::Not;

use fastly::http::StatusCode;
use fastly::{Error, Request, Response};

use robotstxt::DefaultMatcher;

#[fastly::main]
fn main(req: Request) -> Result<Response, Error> {

    let mut matcher = DefaultMatcher::default();
    let robots_body = r#"
                    user-agent: FooBot
                    disallow: /
                    User-agent: *
                    Allow: /
                    Disallow: /admin/*
                    "#;

    // assert_eq!(false, matcher.one_agent_allowed_by_robots(robots_body, "FooBot", "https://foo.com/"));

    let user_agent = req.get_header_str("user-agent").unwrap_or("");
    let url = req.get_url_str();

    if user_agent.to_lowercase().contains("bot") && matcher.one_agent_allowed_by_robots(robots_body, &user_agent, url).not(){
        return Ok(Response::from_status(StatusCode::NOT_ACCEPTABLE))       
    };

    Ok(Response::from_status(StatusCode::OK))
}

// To test, run the following.
// Disallowed
// http "http://127.0.0.1:7676/admin/" user-agent:bot
// http "http://127.0.0.1:7676/" user-agent:foobot

// Allowed
// http "http://127.0.0.1:7676/" user-agent:bot