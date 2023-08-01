# Snippet rate-limiter-v1-origin_waf_response-init-init : 100
# Begin rate-limiter Fastly Edge Rate Limiting
penaltybox rl_origin_waf_response_pb {}
ratecounter rl_origin_waf_response_rc {}

table rl_origin_waf_response_methods {
  "GET": "true",
  "PUT": "true",
  "TRACE": "true",
  "POST": "true",
  "HEAD": "true",
  "DELETE": "true",
  "PATCH": "true",
  "OPTIONS": "true",
}

#### Start rate-limiter Fastly Edge Rate Limiting
sub vcl_recv {
    # call rl_origin_waf_response_process;
      if (req.restarts == 0 && fastly.ff.visits_this_service == 0
      && table.contains(rl_origin_waf_response_methods, req.method)
      ) {
        if (ratelimit.penaltybox_has(rl_origin_waf_response_pb, client.ip)) {
            error 829 "Rate limiter: Too many requests for origin_waf_response";
        }
      }
}
#### End rate-limiter Fastly Edge Rate Limiting

#### Start check backend response status code
sub vcl_fetch {
    # perform check based on the origin response. 206 status makes for easier testing and reporting
    if (beresp.status == 406 || beresp.status == 206) {
        log "406 or 206 response";
        ratelimit.penaltybox_add(rl_origin_waf_response_pb, client.ip, 10m);
    }
}
##### End check backend response status code

# Useful troubleshooting based on the response - Start
/* sub vcl_deliver {
  if (req.http.fastly-debug == "1"){
    set resp.http.X-ERL-PenaltyBox-has = ratelimit.penaltybox_has(rl_origin_waf_response_pb, client.ip);
  }
} */
# Useful troubleshooting based on the response - End

sub vcl_error {
    # Snippet rate-limiter-v1-origin_waf_response-error-error : 100
    # Begin rate-limiter Fastly Edge Rate Limiting - default edge rate limiting error - origin_waf_response
  if (obj.status == 829 && obj.response == "Rate limiter: Too many requests for origin_waf_response") {
    set obj.status = 429;
    set obj.response = "Too Many Requests";
    set obj.http.Content-Type = "text/html";
    synthetic.base64 "PGh0bWw+Cgk8aGVhZD4KCQk8dGl0bGU+VG9vIE1hbnkgUmVxdWVzdHM8L3RpdGxlPgoJPC9oZWFkPgoJPGJvZHk+CgkJPHA+VG9vIE1hbnkgUmVxdWVzdHMgdG8gdGhlIHNpdGU8L3A+Cgk8L2JvZHk+CjwvaHRtbD4=";
    return(deliver);
  }
    # End rate-limiter Fastly Edge Rate Limiting - default edge rate limiting error - origin_waf_response
}
