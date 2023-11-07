
# Snippet rate-limiter-v1-green_gandolf-init
penaltybox rl_green_gandolf_pb {}
ratecounter rl_green_gandolf_rc {}
table rl_green_gandolf_methods {
  "GET": "true",
  "PUT": "true",
  "TRACE": "true",
  "POST": "true",
  "HEAD": "true",
  "DELETE": "true",
  "PATCH": "true",
  "OPTIONS": "true",
}
sub rl_green_gandolf_process {
  declare local var.rl_green_gandolf_limit INTEGER;
  declare local var.rl_green_gandolf_window INTEGER;
  declare local var.rl_green_gandolf_ttl TIME;
  declare local var.rl_green_gandolf_entry STRING;
  set var.rl_green_gandolf_limit = 100;
  set var.rl_green_gandolf_window = 60;
  set var.rl_green_gandolf_ttl = 2m;
  set var.rl_green_gandolf_entry = client.ip;
  if (req.restarts == 0 && fastly.ff.visits_this_service == 0
      && table.contains(rl_green_gandolf_methods, req.method)
      ) {
    if (ratelimit.check_rate(var.rl_green_gandolf_entry
        , rl_green_gandolf_rc, 1
        , var.rl_green_gandolf_window
        , var.rl_green_gandolf_limit
        , rl_green_gandolf_pb
        , var.rl_green_gandolf_ttl)
        ) {
      set req.http.Fastly-SEC-RateLimit = "true";
      error 829 "Rate limiter: Too many requests for green_gandolf";
    }
  }
}

sub vcl_miss {
    # Snippet rate-limiter-v1-green_gandolf-miss
    call rl_green_gandolf_process;
}

sub vcl_pass {
    # Snippet rate-limiter-v1-green_gandolf-pass
    call rl_green_gandolf_process;
}

sub vcl_error {
    # Snippet rate-limiter-v1-green_gandolf-error
    if (obj.status == 829 && obj.response == "Rate limiter: Too many requests for green_gandolf") {
        set obj.status = 429;
        set obj.response = "Too Many Requests";
        set obj.http.Content-Type = "text/html";
        synthetic.base64 "PGh0bWw+Cgk8aGVhZD4KCQk8dGl0bGU+VG9vIE1hbnkgUmVxdWVzdHM8L3RpdGxlPgoJPC9oZWFkPgoJPGJvZHk+CgkJPHA+VG9vIE1hbnkgUmVxdWVzdHMgdG8gdGhlIHNpdGU8L3A+Cgk8L2JvZHk+CjwvaHRtbD4=";
        return(deliver);
    }
}