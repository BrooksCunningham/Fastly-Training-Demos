penaltybox rl_payments_pb {}
ratecounter rl_payments_rc {}

penaltybox rl_default_pb {}
ratecounter rl_default_rc {}

sub rate_limit_process {
  # log "start rl_process";

  declare local var.rl_client_id STRING;
  set var.rl_client_id = "my-client-id-value";
  # set var.rl_client_id = req.http.rl-key;

  if (std.strlen(req.http.no-rl-increment) > 0 ){
    # log "inc rate payments by 0";
    set req.http.X-Last-60s-Hits-payments = ratelimit.ratecounter_increment(rl_payments_rc, var.rl_client_id, 0); 
    # log "payments bucket: " + ratecounter.rl_payments_rc.bucket.60s;

    # log "inc rate default by 0";
    set req.http.X-Last-60s-Hits-default = ratelimit.ratecounter_increment(rl_default_rc, var.rl_client_id, 0);
    # log "default bucket: " + ratecounter.rl_default_rc.bucket.60s;
  } else {
    if (std.strlen(var.rl_client_id) > 0){
        # log "inc rate default by 1";
        set req.http.X-Last-60s-Hits-default = ratelimit.ratecounter_increment(rl_default_rc, var.rl_client_id, 1);
        # log "default bucket: " + ratecounter.rl_default_rc.bucket.60s;
    } else {
        # log "miss default";
        set req.http.X-Last-60s-Hits-default = ratelimit.ratecounter_increment(rl_default_rc, var.rl_client_id, 0);
        # log "default bucket: " + ratecounter.rl_default_rc.bucket.60s;
    }

    if (req.url.path ~ "payments"){
      if (std.strlen(var.rl_client_id) > 0) {    
        # log "inc rate payments by 1";
        set req.http.X-Last-60s-Hits-payments = ratelimit.ratecounter_increment(rl_payments_rc, var.rl_client_id, 1); 
        # log "payments bucket: " + ratecounter.rl_payments_rc.bucket.60s;
      }
    } else {
      # log "miss payments";
      # log "inc rate payments by 0";
      set req.http.X-Last-60s-Hits-payments = ratelimit.ratecounter_increment(rl_payments_rc, var.rl_client_id, 0); 
      # log "payments bucket: " + ratecounter.rl_payments_rc.bucket.60s;
    }
  }
}

sub vcl_recv {
  call rate_limit_process;
  # set req.http.host = "http-me.edgecompute.app";
}
