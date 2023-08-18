#### Fastly VCL Service - Start
resource "fastly_service_vcl" "frontend-vcl-service" {
  name = "VCL Service - NGWAF edge deploy ${var.USER_VCL_SERVICE_DOMAIN_NAME}"

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

  # Dictionary for NGWAF Edge deployment
  dictionary {
    name          = var.Edge_Security_dictionary
    force_destroy = true
  }

  #### NGWAF Dynamic Snippets - MANAGED BY FASTLY - Start
  dynamicsnippet {
    name     = "ngwaf_config_init"
    type     = "init"
    priority = 0
  }
  dynamicsnippet {
    name     = "ngwaf_config_miss"
    type     = "miss"
    priority = 9000
  }
  dynamicsnippet {
    name     = "ngwaf_config_pass"
    type     = "pass"
    priority = 9000
  }
  dynamicsnippet {
    name     = "ngwaf_config_deliver"
    type     = "deliver"
    priority = 9000
  }
  #### NGWAF Dynamic Snippets - MANAGED BY FASTLY - End

  # Add a request header so that the NGWAF service will return the necessary logging headers
  snippet {
    name = "add_ngwaf_log_headers"
    type = "recv"
    content = file("${path.module}/vcl/add_ngwaf_log_headers.vcl")
    priority = 110
  }

  # sets the NGWAF response headers so that the response always includes the headers
  snippet {
    name = "set_ngwaf_log_headers"
    type = "deliver"
    content = file("${path.module}/vcl/set_ngwaf_resp_log_headers.vcl")
    priority = 9100
  }

  ##### It is necessecary to disable caching so that all requests go to NGWAF for inspection
  snippet {
    name = "Disable caching"
    content = file("${path.module}/vcl/disable_caching.vcl")
    type = "recv"
    priority = 900
  }

  product_enablement {
    origin_inspector = true
  }

  force_destroy = true
}

resource "fastly_service_dictionary_items" "edge_security_dictionary_items" {
  for_each = {
    for d in fastly_service_vcl.frontend-vcl-service.dictionary : d.name => d if d.name == var.Edge_Security_dictionary
  }
  
  service_id = fastly_service_vcl.frontend-vcl-service.id
  dictionary_id = each.value.dictionary_id
  items = {
    Enabled: "100"
  }
}

resource "fastly_service_dynamic_snippet_content" "ngwaf_config_init" {
  for_each = {
  for d in fastly_service_vcl.frontend-vcl-service.dynamicsnippet : d.name => d if d.name == "ngwaf_config_init"
  }

  service_id = fastly_service_vcl.frontend-vcl-service.id
  snippet_id = each.value.snippet_id

  content = "### Fastly managed ngwaf_config_init"
  
  manage_snippets = false
}

resource "fastly_service_dynamic_snippet_content" "ngwaf_config_miss" {
  for_each = {
  for d in fastly_service_vcl.frontend-vcl-service.dynamicsnippet : d.name => d if d.name == "ngwaf_config_miss"
  }

  service_id = fastly_service_vcl.frontend-vcl-service.id
  snippet_id = each.value.snippet_id

  content = "### Fastly managed ngwaf_config_miss"

  manage_snippets = false
}

resource "fastly_service_dynamic_snippet_content" "ngwaf_config_pass" {
  for_each = {
  for d in fastly_service_vcl.frontend-vcl-service.dynamicsnippet : d.name => d if d.name == "ngwaf_config_pass"
  }

  service_id = fastly_service_vcl.frontend-vcl-service.id
  snippet_id = each.value.snippet_id

  content = "### Fastly managed ngwaf_config_pass"

  manage_snippets = false
}

resource "fastly_service_dynamic_snippet_content" "ngwaf_config_deliver" {
  for_each = {
  for d in fastly_service_vcl.frontend-vcl-service.dynamicsnippet : d.name => d if d.name == "ngwaf_config_deliver"
  }

  service_id = fastly_service_vcl.frontend-vcl-service.id
  snippet_id = each.value.snippet_id

  content = "### Fastly managed ngwaf_config_deliver"

  manage_snippets = false
}
#### Fastly VCL Service - End

#### Edge deploy and sync - Start
provider "sigsci" {
  corp = var.NGWAF_CORP
  email = var.NGWAF_EMAIL
  auth_token = var.NGWAF_TOKEN
  fastly_api_key = var.FASTLY_API_KEY
}

resource "sigsci_edge_deployment" "ngwaf_edge_site_service" {
  # https://registry.terraform.io/providers/signalsciences/sigsci/latest/docs/resources/edge_deployment
  site_short_name = var.NGWAF_SITE
}

resource "sigsci_edge_deployment_service" "ngwaf_edge_service_link" {
  # https://registry.terraform.io/providers/signalsciences/sigsci/latest/docs/resources/edge_deployment_service
  site_short_name = var.NGWAF_SITE
  fastly_sid      = fastly_service_vcl.frontend-vcl-service.id

  activate_version = true
  percent_enabled = 100

  depends_on = [
    sigsci_edge_deployment.ngwaf_edge_site_service,
    fastly_service_vcl.frontend-vcl-service,
    fastly_service_dictionary_items.edge_security_dictionary_items,
    fastly_service_dynamic_snippet_content.ngwaf_config_init,
    fastly_service_dynamic_snippet_content.ngwaf_config_miss,
    fastly_service_dynamic_snippet_content.ngwaf_config_pass,
    fastly_service_dynamic_snippet_content.ngwaf_config_deliver,
  ]
}

resource "sigsci_edge_deployment_service_backend" "ngwaf_edge_service_backend_sync" {
  site_short_name = var.NGWAF_SITE
  fastly_sid      = fastly_service_vcl.frontend-vcl-service.id

  fastly_service_vcl_active_version = fastly_service_vcl.frontend-vcl-service.active_version

  depends_on = [
    sigsci_edge_deployment_service.ngwaf_edge_service_link,
  ]
}

#### Edge deploy and sync - End

output "live_waf_love_ngwaf_edge_deploy" {
  value = <<tfmultiline
  
  #### Click the URL to go to the Fastly VCL service ####
  https://cfg.fastly.com/${fastly_service_vcl.frontend-vcl-service.id}
    
  tfmultiline

  description = "Output hints on what to do next."

}
