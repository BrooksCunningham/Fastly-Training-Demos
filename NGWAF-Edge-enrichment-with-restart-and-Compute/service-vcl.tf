# Configure the Fastly Provider
provider "fastly" {
  api_key = var.FASTLY_API_KEY
}

#### Fastly VCL Service - Start
resource "fastly_service_vcl" "frontend_vcl_service" {
  name = "Frontend VCL Service - NGWAF edge deploy ${var.SERVICE_VCL_FRONTEND_DOMAIN_NAME}"

  domain {
    name    = var.SERVICE_VCL_FRONTEND_DOMAIN_NAME
    comment = "Frontend VCL Service - NGWAF edge deploy"
  }
  backend {
    address           = var.SERVICE_VCL_BACKEND_HOSTNAME
    name              = "vcl_service_origin"
    port              = 443
    use_ssl           = true
    ssl_cert_hostname = var.SERVICE_VCL_BACKEND_HOSTNAME
    ssl_sni_hostname  = var.SERVICE_VCL_BACKEND_HOSTNAME
    override_host     = var.SERVICE_VCL_BACKEND_HOSTNAME
    request_condition = "backend always false"
  }

  backend {
    address           = fastly_service_compute.compute_service.name
    name              = "compute_client_id_check_origin"
    port              = 443
    use_ssl           = true
    ssl_cert_hostname = fastly_service_compute.compute_service.name
    ssl_sni_hostname  = fastly_service_compute.compute_service.name
    override_host     = fastly_service_compute.compute_service.name
    request_condition = "backend always false"
  }

  condition {
    name      = "backend always false"
    priority  = 100
    statement = "false"
    type      = "REQUEST"
  }

  snippet {
    name     = "default backend - recv"
    content  = "set req.backend = F_vcl_service_origin;"
    type     = "recv"
    priority = 0
  }

  snippet {
    name     = "check client id - init"
    content  = file("${path.module}/vcl/check-identifier-and-restart_init.vcl")
    type     = "init"
    priority = 100
  }

  snippet {
    name     = "check client id - miss"
    content  = file("${path.module}/vcl/check-identifier-and-restart_miss-pass.vcl")
    type     = "miss"
    priority = 100
  }

  snippet {
    name     = "check client id - pass"
    content  = file("${path.module}/vcl/check-identifier-and-restart_miss-pass.vcl")
    type     = "pass"
    priority = 100
  }

  snippet {
    name     = "check client id - deliver"
    content  = file("${path.module}/vcl/check-identifier-and-restart_deliver.vcl")
    type     = "deliver"
    priority = 100
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

  dictionary {
    name = "Edge_Security"
  }


  #   lifecycle {
  #     ignore_changes = [
  #       product_enablement,
  #     ]
  #   }

  force_destroy = true
}

resource "fastly_service_dictionary_items" "edge_security_dictionary_items" {
  for_each = {
    for d in fastly_service_vcl.frontend_vcl_service.dictionary : d.name => d if d.name == "Edge_Security"
  }
  service_id    = fastly_service_vcl.frontend_vcl_service.id
  dictionary_id = each.value.dictionary_id
  items = {
    Enabled : "100"
  }
}

resource "fastly_service_dynamic_snippet_content" "ngwaf_config_init" {
  for_each = {
    for d in fastly_service_vcl.frontend_vcl_service.dynamicsnippet : d.name => d if d.name == "ngwaf_config_init"
  }

  service_id = fastly_service_vcl.frontend_vcl_service.id
  snippet_id = each.value.snippet_id

  content = "### Fastly managed ngwaf_config_init"

  manage_snippets = false
}

resource "fastly_service_dynamic_snippet_content" "ngwaf_config_miss" {
  for_each = {
    for d in fastly_service_vcl.frontend_vcl_service.dynamicsnippet : d.name => d if d.name == "ngwaf_config_miss"
  }

  service_id = fastly_service_vcl.frontend_vcl_service.id
  snippet_id = each.value.snippet_id

  content = "### Fastly managed ngwaf_config_miss"

  manage_snippets = false
}

resource "fastly_service_dynamic_snippet_content" "ngwaf_config_pass" {
  for_each = {
    for d in fastly_service_vcl.frontend_vcl_service.dynamicsnippet : d.name => d if d.name == "ngwaf_config_pass"
  }

  service_id = fastly_service_vcl.frontend_vcl_service.id
  snippet_id = each.value.snippet_id

  content = "### Fastly managed ngwaf_config_pass"

  manage_snippets = false
}

resource "fastly_service_dynamic_snippet_content" "ngwaf_config_deliver" {
  for_each = {
    for d in fastly_service_vcl.frontend_vcl_service.dynamicsnippet : d.name => d if d.name == "ngwaf_config_deliver"
  }

  service_id = fastly_service_vcl.frontend_vcl_service.id
  snippet_id = each.value.snippet_id

  content = "### Fastly managed ngwaf_config_deliver"

  manage_snippets = false
}

#### Fastly VCL Service - End

output "live_laugh_love_ngwaf" {
  value = <<tfmultiline
  
  #### Click the URL to go to the Fastly VCL service ####
  https://cfg.fastly.com/${fastly_service_vcl.frontend_vcl_service.id}
  
  #### Send request with curl and look for client-id-lookup. ####
  curl -s "https://${var.SERVICE_VCL_FRONTEND_DOMAIN_NAME}/anything/whydopirates?likeurls=theargs" -d foo=bar | jq
  
  tfmultiline

  description = "Output hints on what to do next."

}
