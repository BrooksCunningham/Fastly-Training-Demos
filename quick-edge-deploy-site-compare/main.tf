# Configure the Fastly Provider
provider "fastly" {
  api_key = var.FASTLY_API_KEY
}

#### Fastly VCL Service - Start
resource "fastly_service_vcl" "frontend-vcl-service" {
  name = var.USER_VCL_SERVICE_DOMAIN_NAME

  domain {
    name    = var.USER_VCL_SERVICE_DOMAIN_NAME
    comment = "Frontend VCL Service - NGWAF edge deploy"
  }
  backend {
    address = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
    name = "vcl_service_origin"
    port    = 443
    use_ssl = true
    ssl_cert_hostname = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
    ssl_sni_hostname = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
    override_host = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
  }

  #### Only disable caching for testing. Do not disable caching for production traffic.
  # snippet {
  #   name = "Disable caching"
  #   content = file("${path.module}/vcl/disable_caching.vcl")
  #   type = "recv"
  #   priority = 100
  # }


#   lifecycle {
#     ignore_changes = [
#       product_enablement,
#     ]
#   }

  force_destroy = true
}

#### Fastly VCL Service - End

output "live_laugh_love_fastly" {
  value = <<tfmultiline
  
  #### Click the URL to go to the Fastly VCL service ####
  https://cfg.fastly.com/${fastly_service_vcl.frontend-vcl-service.id}
  
  #### Send a test request with curl. ####
  curl -i "https://${var.USER_VCL_SERVICE_DOMAIN_NAME}/anything/whydopirates?likeurls=theargs" -d foo=bar

  #### Send an test as traversal with curl. ####
  curl -i "https://${var.USER_VCL_SERVICE_DOMAIN_NAME}/anything/myattackreq?i=../../../../etc/passwd'" -d foo=bar


  #### Troubleshoot the logging configuration if necessary. ####
  https://docs.fastly.com/en/guides/setting-up-remote-log-streaming#troubleshooting-common-logging-errors
  curl https://api.fastly.com/service/${fastly_service_vcl.frontend-vcl-service.id}/logging_status -H fastly-key:$FASTLY_API_KEY
  
  tfmultiline

  description = "Output hints on what to do next."

}