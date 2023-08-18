#### vcl_deliver
#### Always send the headers back in the response for evaluation by C@E.

if(fastly.ff.visits_this_service == 0){

    set resp.http.ngwaf-agentresponse = req.http.x-sigsci-agentresponse;
    set resp.http.ngwaf-decision-ms = req.http.x-sigsci-decision-ms;
    set resp.http.ngwaf-tags = req.http.x-sigsci-tags;
}

