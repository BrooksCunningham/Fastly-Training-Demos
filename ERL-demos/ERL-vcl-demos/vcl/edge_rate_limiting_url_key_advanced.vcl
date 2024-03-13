
# Snippet rate-limiter-v1-grey_aragon-init
penaltybox rl_grey_aragon_pb {}
ratecounter rl_grey_aragon_rc {}
table rl_grey_aragon_methods {
  "GET": "true",
  "PUT": "true",
  "TRACE": "true",
  "POST": "true",
  "HEAD": "true",
  "DELETE": "true",
  "PATCH": "true",
  "OPTIONS": "true",
}

table rl_sub_uri_paths {
  "/foo/v1/menu/": "menu",
  "/foo/v1/subscribe/": "subscribe",
  "/fiddle/v1/": "fiddle",
}

sub rl_grey_aragon_process {
  declare local var.rl_grey_aragon_limit INTEGER;
  declare local var.rl_grey_aragon_window INTEGER;
  declare local var.rl_grey_aragon_ttl TIME;
  declare local var.rl_grey_aragon_entry STRING;
  set var.rl_grey_aragon_limit = 10;
  set var.rl_grey_aragon_window = 60;
  set var.rl_grey_aragon_ttl = 4m;
  
  # Use the path for the rate limit key
  set var.rl_grey_aragon_entry = req.url.path;
  if (req.restarts == 0 && fastly.ff.visits_this_service == 0
      && table.contains(rl_grey_aragon_methods, req.method)
      ) {
    # Need specific checks for the subpaths

    if (std.tolower(req.url.path) ~ "/foo/v1/menu/") {
      log "Yes match " + table.lookup(rl_sub_uri_paths, "/foo/v1/menu/");
      # or check for rate
      if (ratelimit.check_rate(table.lookup(rl_sub_uri_paths, "/foo/v1/menu/")
        , rl_grey_aragon_rc, 1
        , var.rl_grey_aragon_window
        , var.rl_grey_aragon_limit
        , rl_grey_aragon_pb
        , var.rl_grey_aragon_ttl)
        ) {
        set req.http.Fastly-SEC-RateLimit = "true";
        error 829 "Rate limiter: Too many requests for grey_aragon";
      }
    } else if (std.tolower(req.url.path) ~ "/foo/v1/subscribe/") {
        log "Yes match " + table.lookup(rl_sub_uri_paths, "/foo/v1/subscribe/") ;
        # or check for rate
        if (ratelimit.check_rate(table.lookup(rl_sub_uri_paths, "/foo/v1/subscribe/")
          , rl_grey_aragon_rc, 1
          , var.rl_grey_aragon_window
          , var.rl_grey_aragon_limit
          , rl_grey_aragon_pb
          , var.rl_grey_aragon_ttl)
          ) {
        set req.http.Fastly-SEC-RateLimit = "true";
        error 829 "Rate limiter: Too many requests for grey_aragon";
      }
    } else if (std.tolower(req.url.path) ~ "/fiddle/v1/") {
        log "Yes match " + table.lookup(rl_sub_uri_paths, "/fiddle/v1/");
        if (ratelimit.check_rate(table.lookup(rl_sub_uri_paths, "/fiddle/v1/")
        , rl_grey_aragon_rc, 1
        , var.rl_grey_aragon_window
        , var.rl_grey_aragon_limit
        , rl_grey_aragon_pb
        , var.rl_grey_aragon_ttl)
        ) {
      set req.http.Fastly-SEC-RateLimit = "true";
      error 829 "Rate limiter: Too many requests for grey_aragon";
    }
    } else {
      #check rate for any non-matching URLs
        if (ratelimit.check_rate(var.rl_grey_aragon_entry
        , rl_grey_aragon_rc, 1
        , var.rl_grey_aragon_window
        , var.rl_grey_aragon_limit
        , rl_grey_aragon_pb
        , var.rl_grey_aragon_ttl)
        ) {
      set req.http.Fastly-SEC-RateLimit = "true";
      error 829 "Rate limiter: Too many requests for grey_aragon";
      }
    }
  }
}

sub vcl_miss {
    # Snippet rate-limiter-v1-grey_aragon-miss
    call rl_grey_aragon_process;
}

sub vcl_pass {
    # Snippet rate-limiter-v1-grey_aragon-pass
    call rl_grey_aragon_process;
}

# Only set response headers when debugging to avoid giving attackers additional information
/* sub vcl_deliver {
  set resp.http.rate = ratecounter.rl_grey_aragon_rc.rate.60s;
  set resp.http.rate-counter = ratecounter.rl_grey_aragon_rc.bucket.60s;
} */

sub vcl_error {
    # Snippet rate-limiter-v1-grey_aragon-error
    if (obj.status == 829 && obj.response == "Rate limiter: Too many requests for grey_aragon") {
        set obj.status = 429;
        set obj.response = "Too Many Requests";
        set obj.http.Content-Type = "text/html";
        synthetic.base64 "PGh0bWw+Cgk8aGVhZD4KCQk8dGl0bGU+VG9vIE1hbnkgUmVxdWVzdHM8L3RpdGxlPgoJPC9oZWFkPgoJPGJvZHk+CgkJPHA+VG9vIE1hbnkgUmVxdWVzdHMgdG8gdGhlIHNpdGU8L3A+Cgk8L2JvZHk+CjwvaHRtbD4=";
        return(deliver);
    }
}
