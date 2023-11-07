
# Snippet rate-limiter-v1-orange_gandolf-init
penaltybox rl_orange_gandolf_pb {}
ratecounter rl_orange_gandolf_rc {}
table rl_orange_gandolf_methods {
  "GET": "true",
  "PUT": "true",
  "TRACE": "true",
  "POST": "true",
  "HEAD": "true",
  "DELETE": "true",
  "PATCH": "true",
  "OPTIONS": "true",
}

sub rl_orange_gandolf_process {
  declare local var.rl_orange_gandolf_limit INTEGER;
  declare local var.rl_orange_gandolf_window INTEGER;
  declare local var.rl_orange_gandolf_ttl TIME;
  declare local var.rl_orange_gandolf_entry STRING;
  set var.rl_orange_gandolf_limit = 10;
  set var.rl_orange_gandolf_window = 10;
  set var.rl_orange_gandolf_ttl = 4m;
  
  # Use the request header user-id for the rate limit key
  set var.rl_orange_gandolf_entry = req.http.user-id;

  // Add every entry into the Penalty Box
  // if the entry is NOT in the Penalty Box, then do something
  // else do nothing
  if (std.strlen(var.rl_orange_gandolf_entry) > 0 
  && !ratelimit.penaltybox_has(rl_orange_gandolf_pb, var.rl_orange_gandolf_entry)) {
    // Setting the header before adding the entry to the PB
    set req.http.Fastly-SEC-pbhas = ratelimit.penaltybox_has(rl_orange_gandolf_pb, var.rl_orange_gandolf_entry);
    // Add the entry into the penalty box
    ratelimit.penaltybox_add(rl_orange_gandolf_pb, var.rl_orange_gandolf_entry, 2m);
  } else {
    // sets the header with a value of 1 if the entry exists
    set req.http.Fastly-SEC-pbhas = ratelimit.penaltybox_has(rl_orange_gandolf_pb, var.rl_orange_gandolf_entry);
  } 
}

sub vcl_miss {
    # Snippet rate-limiter-v1-orange_gandolf-miss
    call rl_orange_gandolf_process;
}

sub vcl_pass {
    # Snippet rate-limiter-v1-orange_gandolf-pass
    call rl_orange_gandolf_process;
}

# Tarpits responses with the req header is set with a value of 0
sub vcl_deliver {
  if (req.http.Fastly-SEC-pbhas == "0") {
    resp.tarpit(2, 100);
  }
  # Only exists for debugging. Remove for production.
  set resp.http.Fastly-SEC-pbhas = req.http.Fastly-SEC-pbhas; 
}

/* sub vcl_error {
    # Snippet rate-limiter-v1-orange_gandolf-error
    if (obj.status == 829 && obj.response == "Rate limiter: Too many requests for orange_gandolf") {
        set obj.status = 429;
        set obj.response = "Too Many Requests";
        set obj.http.Content-Type = "text/html";
        synthetic.base64 "PGh0bWw+Cgk8aGVhZD4KCQk8dGl0bGU+VG9vIE1hbnkgUmVxdWVzdHM8L3RpdGxlPgoJPC9oZWFkPgoJPGJvZHk+CgkJPHA+VG9vIE1hbnkgUmVxdWVzdHMgdG8gdGhlIHNpdGU8L3A+Cgk8L2JvZHk+CjwvaHRtbD4=";
        return(deliver);
    }
} */
