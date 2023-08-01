
# Snippet rate-limiter-v1-green_watson-init
penaltybox rl_green_watson_pb {}
ratecounter rl_green_watson_rc {}
table rl_green_watson_methods {
  "GET": "true",
  "PUT": "true",
  "TRACE": "true",
  "POST": "true",
  "HEAD": "true",
  "DELETE": "true",
  "PATCH": "true",
  "OPTIONS": "true",
}

sub rl_green_watson_process {
  declare local var.rl_green_watson_limit INTEGER;
  declare local var.rl_green_watson_window INTEGER;
  declare local var.rl_green_watson_ttl TIME;
  declare local var.rl_green_watson_entry STRING;
  set var.rl_green_watson_limit = 10;
  set var.rl_green_watson_window = 10;
  set var.rl_green_watson_ttl = 4m;
  
  # Use the request header user-id for the rate limit key
  set var.rl_green_watson_entry = req.http.user-id;

  # TODOs
  # add table to configure logging or blocking
  # add table to only action on specific user agent.
  
  if (req.restarts == 0 && fastly.ff.visits_this_service == 0
      && table.contains(rl_green_watson_methods, req.method)
      && std.tolower(req.http.user-agent) ~ "python-requests"
      && std.strlen(var.rl_green_watson_entry) > 0
      ) {
      #check rate for the request header user-id
        if (ratelimit.check_rate(var.rl_green_watson_entry
        , rl_green_watson_rc, 1
        , var.rl_green_watson_window
        , var.rl_green_watson_limit
        , rl_green_watson_pb
        , var.rl_green_watson_ttl)
        ) {

          # Set information for potentially logging the excessive rate
          set req.http.Fastly-SEC-RateLimit = "true";

          # Only take the blocking action if the dictionary has the key "blocking" with the value "true"
          if (table.lookup(erl_config, "blocking", "false") == "true"
          ){
            error 829 "Rate limiter: Too many requests for green_watson";
          }      
      }
  }
}

sub vcl_miss {
    # Snippet rate-limiter-v1-green_watson-miss
    call rl_green_watson_process;
}

sub vcl_pass {
    # Snippet rate-limiter-v1-green_watson-pass
    call rl_green_watson_process;
}

# Only set response headers when debugging to avoid giving attackers additional information
/* sub vcl_deliver {
  set resp.http.rate = ratecounter.rl_green_watson_rc.rate.60s;
  set resp.http.rate-counter = ratecounter.rl_green_watson_rc.bucket.60s;
} */

sub vcl_error {
    # Snippet rate-limiter-v1-green_watson-error
    if (obj.status == 829 && obj.response == "Rate limiter: Too many requests for green_watson") {
        set obj.status = 429;
        set obj.response = "Too Many Requests";
        set obj.http.Content-Type = "text/html";
        synthetic.base64 "PGh0bWw+Cgk8aGVhZD4KCQk8dGl0bGU+VG9vIE1hbnkgUmVxdWVzdHM8L3RpdGxlPgoJPC9oZWFkPgoJPGJvZHk+CgkJPHA+VG9vIE1hbnkgUmVxdWVzdHMgdG8gdGhlIHNpdGU8L3A+Cgk8L2JvZHk+CjwvaHRtbD4=";
        return(deliver);
    }
}
