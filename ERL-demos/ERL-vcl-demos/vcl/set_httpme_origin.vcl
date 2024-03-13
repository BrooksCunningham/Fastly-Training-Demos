# place in VCL init

sub set_httpme_origin_process {
    if (std.strlen(req.http.httpme) > 0) {
        set req.backend = F_fastly_http_me_origin ;
    }
}

sub vcl_miss {
    # Snippet
    call set_httpme_origin_process;
}

sub vcl_pass {
    # Snippet
    call set_httpme_origin_process;
}
