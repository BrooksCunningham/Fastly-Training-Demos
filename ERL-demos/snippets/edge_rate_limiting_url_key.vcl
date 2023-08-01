
# Snippet rate-limiter-v1-blue_frodo-init
penaltybox rl_blue_frodo_pb {}
ratecounter rl_blue_frodo_rc {}
table rl_blue_frodo_methods {
  "GET": "true",
  "PUT": "true",
  "TRACE": "true",
  "POST": "true",
  "HEAD": "true",
  "DELETE": "true",
  "PATCH": "true",
  "OPTIONS": "true",
}
sub rl_blue_frodo_process {
  declare local var.rl_blue_frodo_limit INTEGER;
  declare local var.rl_blue_frodo_window INTEGER;
  declare local var.rl_blue_frodo_ttl TIME;
  declare local var.rl_blue_frodo_entry STRING;
  set var.rl_blue_frodo_limit = 10;
  set var.rl_blue_frodo_window = 60;
  set var.rl_blue_frodo_ttl = 4m;
  
  # Use the path for the rate limit key
  set var.rl_blue_frodo_entry = req.url.path;
  if (req.restarts == 0 && fastly.ff.visits_this_service == 0
      && table.contains(rl_blue_frodo_methods, req.method)
      ) {
    if (ratelimit.check_rate(var.rl_blue_frodo_entry
        , rl_blue_frodo_rc, 1
        , var.rl_blue_frodo_window
        , var.rl_blue_frodo_limit
        , rl_blue_frodo_pb
        , var.rl_blue_frodo_ttl)
        ) {
      set req.http.Fastly-SEC-RateLimit = "true";
      error 829 "Rate limiter: Too many requests for blue_frodo";
    }
  }
}

sub vcl_miss {
    # Snippet rate-limiter-v1-blue_frodo-miss
    call rl_blue_frodo_process;
}

sub vcl_pass {
    # Snippet rate-limiter-v1-blue_frodo-pass
    call rl_blue_frodo_process;
}

# Only set response headers when debugging to avoid giving attackers additional information
/* sub vcl_deliver {
  set resp.http.rate = ratecounter.rl_blue_frodo_rc.rate.60s;
  set resp.http.rate-counter = ratecounter.rl_blue_frodo_rc.bucket.60s;
} */

sub vcl_error {
    # Snippet rate-limiter-v1-blue_frodo-error
    if (obj.status == 829 && obj.response == "Rate limiter: Too many requests for blue_frodo") {
        set obj.status = 429;
        set obj.response = "Too Many Requests";
        set obj.http.Content-Type = "text/html";
        synthetic.base64 "PGh0bWw+Cgk8aGVhZD4KCQk8dGl0bGU+VG9vIE1hbnkgUmVxdWVzdHM8L3RpdGxlPgoJPC9oZWFkPgoJPGJvZHk+CgkJPHA+VG9vIE1hbnkgUmVxdWVzdHMgdG8gdGhlIHNpdGU8L3A+Cgk8L2JvZHk+CjwvaHRtbD4=";
        return(deliver);
    }
}
