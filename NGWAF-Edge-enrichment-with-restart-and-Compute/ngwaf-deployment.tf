provider "sigsci" {
  corp           = var.NGWAF_CORP
  email          = var.NGWAF_EMAIL
  auth_token     = var.NGWAF_TOKEN
  fastly_api_key = var.FASTLY_API_KEY
}


resource "sigsci_edge_deployment_service" "ngwaf_edge_service_link" {
  # https://registry.terraform.io/providers/signalsciences/sigsci/latest/docs/resources/edge_deployment_service
  site_short_name = var.NGWAF_SITE
  fastly_sid      = fastly_service_vcl.frontend_vcl_service.id

  activate_version = true
  percent_enabled  = 100

  depends_on = [
    fastly_service_vcl.frontend_vcl_service,
    fastly_service_dictionary_items.edge_security_dictionary_items,
    fastly_service_dynamic_snippet_content.ngwaf_config_init,
    fastly_service_dynamic_snippet_content.ngwaf_config_miss,
    fastly_service_dynamic_snippet_content.ngwaf_config_pass,
    fastly_service_dynamic_snippet_content.ngwaf_config_deliver,
  ]
}

output "ngwaf-deployment-output" {
    value = <<tfmultiline
  
    #### Click the URL to go to the Fastly NGWAF service ####
    https://dashboard.signalsciences.net/corps/${var.NGWAF_CORP}/sites/${var.NGWAF_SITE}

    tfmultiline
}