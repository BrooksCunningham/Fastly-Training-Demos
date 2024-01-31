
# Snippet rate-limiter-v1-red_balrog-init
penaltybox rl_red_balrog_pb {}
# ratecounter rl_red_balrog_rc {}

sub rl_red_balrog_process {
  declare local var.rl_red_balrog_limit INTEGER;
  declare local var.rl_red_balrog_window INTEGER;
  declare local var.rl_red_balrog_ttl TIME;
  declare local var.rl_red_balrog_entry STRING;
  set var.rl_red_balrog_limit = 100;
  set var.rl_red_balrog_window = 60;
  set var.rl_red_balrog_ttl = 2m;
  set var.rl_red_balrog_entry = req.http.user-id;

  if (req.restarts == 0 
  && fastly.ff.visits_this_service == 0
  && req.url ~ "^/fastly/erl/add"
  && req.http.secret-erl-key == "abra"
  && req.backend.is_origin){
    log "erl add"; # http https://erl-demos.global.ssl.fastly.net/fastly/erl/add secret-erl-key:abra user-id:bob foo=bar -p=h
    ratelimit.penaltybox_add(rl_red_balrog_pb, var.rl_red_balrog_entry, var.rl_red_balrog_ttl);
    set req.http.Fastly-SEC-RateLimit = "Added";
  }

  if (req.url ~ "^/fastly/erl/read" 
  && req.http.secret-erl-key == "abra"
  && req.backend.is_origin){

    log "erl read"; # http https://erl-demos.global.ssl.fastly.net/fastly/erl/read secret-erl-key:abra user-id:bob foo=bar -p=h
    if (ratelimit.penaltybox_has(rl_red_balrog_pb, var.rl_red_balrog_entry)) {
      set req.http.Fastly-SEC-RateLimit = "true";
      error 829 "Rate limiter: Too many requests for red_balrog";
    }
    
  }

  if (req.restarts == 0 && fastly.ff.visits_this_service == 0) {
    if (ratelimit.penaltybox_has(rl_red_balrog_pb, var.rl_red_balrog_entry)) {
      set req.http.Fastly-SEC-RateLimit = "true";
      error 829 "Rate limiter: Too many requests for red_balrog";
    }
  }
}

# sub vcl_recv {
#   call rl_red_balrog_process;
# }

sub vcl_miss {
    # Snippet rate-limiter-v1-red_balrog-miss
    call rl_red_balrog_process;
}

sub vcl_pass {
    # Snippet rate-limiter-v1-red_balrog-pass
    call rl_red_balrog_process;
}

sub vcl_error {
    # Snippet rate-limiter-v1-red_balrog-error
    if (obj.status == 829 && obj.response == "Rate limiter: Too many requests for red_balrog") {
        set obj.status = 429;
        set obj.response = "Too Many Requests";
        set obj.http.Content-Type = "text/html";
        synthetic.base64 "PGh0bWw+Cgk8aGVhZD4KCQk8dGl0bGU+VG9vIE1hbnkgUmVxdWVzdHM8L3RpdGxlPgoJPC9oZWFkPgoJPGJvZHk+CgkJPHA+VG9vIE1hbnkgUmVxdWVzdHMgdG8gdGhlIHNpdGU8L3A+Cgk8L2JvZHk+CjwvaHRtbD4=";
        return(deliver);
    }
}