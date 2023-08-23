

#### CloudWAF deploy - Start
# resource "sigsci_corp_cloudwaf_certificate" "test_corp_cloudwaf_certificate" {
#   name = ""
#   certificate_body = ""
#   private_key = ""
# }


resource "sigsci_corp_cloudwaf_instance" "test_corp_cloudwaf" {
    description               = "lab cloudwaf"
    name                      = "lab_cloudwaf"
    region                    = "us-east-1"
    tls_min_version           = "1.2"
    use_uploaded_certificates = false

    workspace_configs {
        client_ip_header   = "Fastly-Client-Ip"
        instance_location  = "advanced"
        listener_protocols = [
            "https",
        ]
        site_name          = "test"

        routes {
            certificate_ids     = []
            connection_pooling  = true
            domains             = [
                "*.global.ssl.fastly.net",
            ]
            origin              = "https://httpbin.org"
            pass_host_header    = false
            trust_proxy_headers = true
        }
    }
}


# terraform import sigsci_corp_cloudwaf_instance.test_corp_cloudwaf id

# terraform import sigsci_corp_cloudwaf_instance.test_corp_cloudwaf f1b41fc7-35d7-4636-bf54-06291d49cc0d


#### CloudWAF deploy - End

output "live_waf_love_ngwaf_edge_deploy" {
  value = <<tfmultiline
  tfmultiline

  #### Click the URL to go to the Fastly VCL service ####
  # https://cfg.fastly.com/${fastly_service_vcl.frontend-vcl-service.id}
  
  #### Send a test request with curl. ####
  # curl -i "https://${var.USER_DOMAIN_NAME}/anything/whydopirates?likeurls=theargs" -d foo=bar

  #### Send an test as traversal with curl. ####
  # curl -i "https://${var.USER_DOMAIN_NAME}/anything/myattackreq?i=../../../../etc/passwd" -d foo=bar
  
  

  description = "Output hints on what to do next."

}
