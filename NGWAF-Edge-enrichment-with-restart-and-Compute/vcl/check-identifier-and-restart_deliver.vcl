  
if (req.restarts < 1 && req.backend == F_compute_client_id_check_origin) {  
    if (resp.status == 200) {
      set req.http.client-id-lookup = "abusive";
    } else {
      set req.http.client-id-lookup = "not-found";
    }
    if (std.strlen(req.http.do-restart) > 0){
      restart;
    }
} 