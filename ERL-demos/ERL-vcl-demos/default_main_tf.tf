# Terraform 0.13+ requires providers to be declared in a "required_providers" block
terraform {
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = ">= 3.0.4"
    }
  }
}

# Configure the Fastly Provider
provider "fastly" {
  api_key = var.FASTLY_API_KEY
}

# Create a Service
resource "fastly_service_vcl" "edge-rate-limiting-terraform-service" {
  name = "edge-rate-limiting-terraform ${var.USER_DOMAIN_NAME}"

  domain {
    name    = var.USER_DOMAIN_NAME
    comment = "demo for configuring edge rate limiting with terraform"
  }

  backend {
    address           = var.USER_DEFAULT_BACKEND_HOSTNAME
    name              = "fastly_origin"
    port              = 443
    use_ssl           = true
    ssl_cert_hostname = var.USER_DEFAULT_BACKEND_HOSTNAME
    ssl_sni_hostname  = var.USER_DEFAULT_BACKEND_HOSTNAME
    override_host     = var.USER_DEFAULT_BACKEND_HOSTNAME
  }

  # TODO create a snippet to switch to this origin. 
  # This is helpful for seeing responses from /anything/
  backend {
    address           = "http-me.edgecompute.app"
    name              = "fastly_http-me_origin"
    port              = 443
    use_ssl           = true
    ssl_cert_hostname = "http-me.edgecompute.app"
    ssl_sni_hostname  = "http-me.edgecompute.app"
    override_host     = "http-me.edgecompute.app"
  }

  ##### Set the http-me.edgecompute.app origin when the http-me request header is present
  # snippet {
  #   name = "set_http-me_origin"
  #   content = file("${path.module}/vcl/set_httpme_origin.vcl")
  #   type = "init"
  #   priority = 100
  # }

  ##### Rate limit by request header "user-id" - Orange frodo
  # snippet {
  #   name = "Edge Rate Limit by user-id request header with dictionaries"
  #   content = file("${path.module}/snippets/edge_rate_limiting_request_header_with_dictionary.vcl")
  #   type = "init"
  #   priority = 115
  # }

  # snippet {
  #   name     = "Edge Rate Limiting low volume"
  #   content  = file("${path.module}/vcl/edge_rate_limiting_low_volume_allinone.vcl")
  #   type     = "init"
  #   priority = 115
  # }

  snippet {
    name     = "Edge Rate Limiting API"
    content  = file("${path.module}/vcl/edge_rate_limiting_api.vcl")
    type     = "init"
    priority = 115
  }

  ##### Rate limit by request header "user-id" and using ERL as state machine - Orange Gandolf
  # snippet {
  #   name = "Edge Rate Limit State Machine"
  #   content = file("${path.module}/snippets/edge_rate_limiting_state_machine.vcl")
  #   type = "init"
  #   priority = 116
  # }


  ##### origin_waf_response
  # snippet {
  #   name = "Origin Response Penalty Box"
  #   content = file("${path.module}/snippets/origin_response_penalty_box.vcl")
  #   type = "init"
  #   priority = 130
  # }

  ##### It is necessecary to disable caching for ERL to increment the counter for origin/backend requests
  # snippet {
  #   name = "Disable caching"
  #   content = file("${path.module}/vcl/disable_caching.vcl")
  #   type = "recv"
  #   priority = 100
  # }

  # dictionary {
  #   name       = "rl_user_agents"
  # }

  dictionary {
    name = "erl_config"
  }

  force_destroy = true
}

# resource "fastly_service_dictionary_items" "rl_user_agents" {
#   for_each = {
#     for d in fastly_service_vcl.edge-rate-limiting-terraform-service.dictionary : d.name => d if d.name == "rl_user_agents"
#   }
#   service_id = fastly_service_vcl.edge-rate-limiting-terraform-service.id
#   dictionary_id = each.value.dictionary_id

#   items = {
#     "python-requests": "true",
#   }
#   manage_items = true
# }



resource "fastly_service_dictionary_items" "erl_config" {
  for_each = {
    for d in fastly_service_vcl.edge-rate-limiting-terraform-service.dictionary : d.name => d if d.name == "erl_config"
  }
  service_id    = fastly_service_vcl.edge-rate-limiting-terraform-service.id
  dictionary_id = each.value.dictionary_id
  items = {
    "blocking" : "true",
  }
  manage_items = true
}

output "live_laugh_love_edge_rate_limiting" {
  # How to test example
  value = <<tfmultiline

    #### Click the URL to go to the service ####
    https://cfg.fastly.com/${fastly_service_vcl.edge-rate-limiting-terraform-service.id}

    # The following commands are useful for testing.
    
    ## Rate Limit based on request header user-id
    siege "https://${var.USER_DOMAIN_NAME}/foo/v1/login" --header "user-id: 1" -t 5s

    ## Rate Limit based on URL
    siege "https://${var.USER_DOMAIN_NAME}/foo/v1/menu/abc" -t 5s

    ## Add IP to Rate Limit Penalty box based on origin data
    echo "GET https://${var.USER_DOMAIN_NAME}/status/206" | vegeta attack -header "vegeta-test:ratelimittest1" -duration=30s  | vegeta report -type=text

    # Run the following curl and vegeta commands in a seperate adjacent windows with domain inspector to see the blocks in the Fastly UI.

    watch -n0.5 'curl -isD - -o /dev/null https://${var.USER_DOMAIN_NAME}/status/200 -H "fastly-debug:1" -H "user-id:xyz-123"'
    
    echo "GET https://${var.USER_DOMAIN_NAME}/status/200" | vegeta attack -header "user-id:abc-123" -duration=120s  | vegeta report -type=text
    
    # Navigate to the Domain Inspector UI
    https://manage.fastly.com/stats/real-time/services/${fastly_service_vcl.edge-rate-limiting-terraform-service.id}/datacenters/all/domains/

  tfmultiline
}
