# Try to follow recommended practices here, https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices

# Configure the Fastly Provider
provider "fastly" {
  api_key = var.FASTLY_API_KEY
}

#### Fastly VCL Service - Start
resource "fastly_service_vcl" "frontend-vcl-service" {
  name = "Frontend VCL Service - ERL and NGWAF rate limiting - ${var.USER_VCL_SERVICE_DOMAIN_NAME}"

  domain {
    name    = var.USER_VCL_SERVICE_DOMAIN_NAME
    comment = "Frontend VCL Service - ERL and NGWAF rate limiting"
  }
  backend {
    address           = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
    name              = "vcl_service_origin"
    port              = 443
    use_ssl           = true
    ssl_cert_hostname = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
    ssl_sni_hostname  = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
    override_host     = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
  }

  #### Adds the necessary header to enable response headers from the NGWAF edge deployment, which may then be used for logging. 
  # Also, removes the sensitive response headers before delivering the response to the client

  #### Only disable caching for testing. Do not disable caching for production traffic.
  # snippet {
  #   name     = "Disable caching"
  #   content  = file("${path.module}/vcl/disable_caching.vcl")
  #   type     = "recv"
  #   priority = 220
  # }

  # snippet {
  #   name     = "Go to NGWAF - pass"
  #   content  = file("${path.module}/vcl/go_to_ngwaf.vcl")
  #   type     = "pass"
  #   priority = 9100
  # }

  # snippet {
  #   name     = "Go to NGWAF - miss"
  #   content  = file("${path.module}/vcl/go_to_ngwaf.vcl")
  #   type     = "miss"
  #   priority = 9100
  # }

  dynamicsnippet {
    name     = "edge_rate_limiting_init"
    type     = "init"
    priority = 0
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
  #### NGWAF Dynamic Snippets - MANAGED BY FASTLY - End

  # Dictionary for NGWAF Edge deployment
  dictionary {
    name          = "Edge_Security"
    force_destroy = true
  }

  product_enablement {
    origin_inspector = true
    domain_inspector = true
  }

  force_destroy = true
}

resource "fastly_service_dynamic_snippet_content" "edge_rate_limiting_init" {
  for_each = {
    for d in fastly_service_vcl.frontend-vcl-service.dynamicsnippet : d.name => d if d.name == "edge_rate_limiting_init"
  }

  service_id = fastly_service_vcl.frontend-vcl-service.id
  snippet_id = each.value.snippet_id

  # content = file("${path.module}/vcl/edge_rate_limiting_with_ngwaf.vcl")
  content = file("${path.module}/vcl/erl_testing.vcl")

  manage_snippets = true
}
resource "fastly_service_dictionary_items" "edge_security_dictionary_items" {
  for_each = {
    for d in fastly_service_vcl.frontend-vcl-service.dictionary : d.name => d if d.name == "Edge_Security"
  }

  service_id    = fastly_service_vcl.frontend-vcl-service.id
  dictionary_id = each.value.dictionary_id
  items = {
    Enabled : "100"
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

resource "sigsci_edge_deployment_service" "ngwaf_edge_service_link" {
  # https://registry.terraform.io/providers/signalsciences/sigsci/latest/docs/resources/edge_deployment_service
  site_short_name = var.NGWAF_SITE
  fastly_sid      = fastly_service_vcl.frontend-vcl-service.id

  activate_version = true
  percent_enabled  = 100

  depends_on = [
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

# terraform show -json | jq '.values.root_module.resources[] | select(.address == "sigsci_site_templated_rule.login_template_rule")'

output "live_laugh_love_ngwaf" {
  value = <<tfmultiline
  
  #### Click the URL to go to the service ####
  https://cfg.fastly.com/${fastly_service_vcl.frontend-vcl-service.id}
  
  #### Send a test request with curl. ####
  curl -X POST -i "https://${var.USER_VCL_SERVICE_DOMAIN_NAME}/anything/erl" -H "rl-identifier:abc-123" -d foo=bar

  #### Load test requests ####
  echo "POST https://${var.USER_VCL_SERVICE_DOMAIN_NAME}/anything/erl" | vegeta attack -header "rl-identifier:abc-123" -duration=10s  | vegeta report -type=text

  #### Live details with load test ####
  echo "POST https://${var.USER_VCL_SERVICE_DOMAIN_NAME}/anything/erl" | vegeta attack -header "rl-identifier:abc-123" -duration=120s  | vegeta encode | \
    jaggr @count=rps \
          hist\[100,200,300,400,500\]:code \
          p25,p50,p95:latency \
          sum:bytes_in \
          sum:bytes_out | \
    jplot rps+code.hist.100+code.hist.200+code.hist.300+code.hist.400+code.hist.500 \
          latency.p95+latency.p50+latency.p25 \
          bytes_in.sum+bytes_out.sum

  #### Wrap the curl in a watch command ####

  watch 'curl -i "https://${var.USER_VCL_SERVICE_DOMAIN_NAME}/anything/erl" -d foo=bar'

  #### Edge inspector for real time stats ####
  https://manage.fastly.com/stats/real-time/services/${fastly_service_vcl.frontend-vcl-service.id}/datacenters/all
  
  tfmultiline

  description = "Output hints on what to do next."

}
