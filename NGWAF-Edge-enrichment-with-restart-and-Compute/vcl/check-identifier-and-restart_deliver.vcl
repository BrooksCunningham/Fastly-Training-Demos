#sub vcl_deliver
if (req.restarts == 0 && fastly.ff.visits_this_service == 0 && req.http.x-client-id-check == "true") {  
    if (resp.status == 200) {
      set req.http.client-id-lookup = "abusive";
    } else {
      set req.http.client-id-lookup = "not-found";
    }
    restart;
} 