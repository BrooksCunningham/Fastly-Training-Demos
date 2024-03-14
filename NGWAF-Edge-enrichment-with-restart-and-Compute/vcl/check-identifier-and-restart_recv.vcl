if (req.restarts < 1 && req.url.path ~ "anything") {
    set req.http.x-sigsci-skip-inspection-once = "client-id-check";
    set req.backend = F_compute_client_id_check_origin;
}