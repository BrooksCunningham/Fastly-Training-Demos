# vcl_init

# use function in miss and pass
sub client_id_check {
    if (req.restarts == 0 && fastly.ff.visits_this_service == 0 && req.url.path ~ "anything") {
        set req.http.x-sigsci-skip-inspection-once = "client-id-check";
        set req.backend = F_compute_client_id_check_origin;
    }
}
