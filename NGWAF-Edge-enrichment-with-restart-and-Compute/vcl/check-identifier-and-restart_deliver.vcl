  
if (req.restarts == 0 && fastly.ff.visits_this_service == 0) {  
    if (resp.status == 200) {
      set req.http.client-id-lookup = "abusive";
    } else {
      set req.http.client-id-lookup = "not-found";
    }
    if (std.strlen(req.http.do-restart) > 0){
      restart;
    }
} 