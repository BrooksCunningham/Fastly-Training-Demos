
# Snippet rate-limiter-v1-red_sauron-init
penaltybox rl_red_sauron_pb {}
ratecounter rl_red_sauron_rc {}
table rl_red_sauron_methods {
  "GET": "true",
  "PUT": "true",
  "TRACE": "true",
  "POST": "true",
  "HEAD": "true",
  "DELETE": "true",
  "PATCH": "true",
  "OPTIONS": "true",
}
sub rl_red_sauron_process {
  declare local var.rl_red_sauron_limit INTEGER;
  declare local var.rl_red_sauron_window INTEGER;
  declare local var.rl_red_sauron_ttl TIME;
  declare local var.rl_red_sauron_entry STRING;
  set var.rl_red_sauron_limit = 10;
  set var.rl_red_sauron_window = 60;
  set var.rl_red_sauron_ttl = 4m;
  
  # Use the client.as.name for the rate limit key, https://developer.fastly.com/reference/vcl/variables/client-connection/client-as-name/
  set var.rl_red_sauron_entry = client.as.name;

  # add check if the request is coming from a hosting provider
  # https://developer.fastly.com/reference/vcl/variables/geolocation/client-geo-proxy-type/
  if (req.restarts == 0 && fastly.ff.visits_this_service == 0
      && table.contains(rl_red_sauron_methods, req.method)
      && client.geo.proxy_type ~ "^hosting"
      ) {

    if (ratelimit.check_rate(var.rl_red_sauron_entry
        , rl_red_sauron_rc, 1
        , var.rl_red_sauron_window
        , var.rl_red_sauron_limit
        , rl_red_sauron_pb
        , var.rl_red_sauron_ttl)
        ) {
      set req.http.Fastly-SEC-RateLimit = "true";
      error 829 "Rate limiter: Too many requests for red_sauron";
    }
  }
}

sub vcl_miss {
    # Snippet rate-limiter-v1-red_sauron-miss
    call rl_red_sauron_process;
}

sub vcl_pass {
    # Snippet rate-limiter-v1-red_sauron-pass
    call rl_red_sauron_process;
}

sub vcl_error {
    # Snippet rate-limiter-v1-red_sauron-error
    if (obj.status == 829 && obj.response == "Rate limiter: Too many requests for red_sauron") {
        set obj.status = 429;
        set obj.response = "Too Many Requests";
        set obj.http.Content-Type = "text/html";
        synthetic.base64 "PGh0bWw+Cgk8aGVhZD4KCQk8dGl0bGU+VG9vIE1hbnkgUmVxdWVzdHM8L3RpdGxlPgoJPC9oZWFkPgoJPGJvZHk+CgkJPHA+VG9vIE1hbnkgUmVxdWVzdHMgdG8gdGhlIHNpdGU8L3A+Cgk8L2JvZHk+CjwvaHRtbD4=";
        return(deliver);
    }
}