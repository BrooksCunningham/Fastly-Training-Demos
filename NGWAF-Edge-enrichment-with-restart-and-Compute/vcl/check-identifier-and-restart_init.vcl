# vcl_init

# use function in miss and pass
sub client_id_check {
    # always unset the request header to avoid a issue where the client may send the header.
    unset req.http.x-client-id-check;
    set bereq.http.x-restarts = req.restarts;

    if (std.strlen(req.http.Orig-Method) > 0){
        set bereq.method = req.http.Orig-Method;
    }

    if (req.restarts == 0 && fastly.ff.visits_this_service == 0 && req.url.path ~ "anything") {
        # Must set the skip inspection header to avoid sending the request directly to NGWAF initially.
        set bereq.http.x-sigsci-skip-inspection-once = "client-id-check";

        # Set the x-client-id-check header so that this may be used in vcl_deliver.
        set req.http.x-client-id-check = "true";
        set req.backend = F_compute_client_id_check_origin;

        # Need to set the request to a GET to preserve the POST body
        # set req.method = req.http.Orig-Method;
        # set req.method = "GET";
        set bereq.method = "GET";
    }
}
