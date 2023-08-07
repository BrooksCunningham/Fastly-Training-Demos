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
    address = var.USER_DEFAULT_BACKEND_HOSTNAME
    name = "fastly_origin"
    port    = 443
    use_ssl = true
    ssl_cert_hostname = var.USER_DEFAULT_BACKEND_HOSTNAME
    ssl_sni_hostname = var.USER_DEFAULT_BACKEND_HOSTNAME
    override_host = var.USER_DEFAULT_BACKEND_HOSTNAME
  }

  # This is helpful for seeing responses from /anything/
  backend {
    address = "http-me.glitch.me"
    name = "fastly_http-me_origin"
    port    = 443
    use_ssl = true
    ssl_cert_hostname = "http-me.glitch.me"
    ssl_sni_hostname = "http-me.glitch.me"
    override_host = "http-me.glitch.me"
  }

  ##### Set the http-me.glitch.me origin when the http-me request header is present
  snippet {
    name = "set_http-me_origin"
    content = file("${path.module}/snippets/set_http-me_origin.vcl")
    type = "init"
    priority = 100
  }

  ##### Rate limit by request header "user-id" - Orange frodo
  # snippet {
  #   name = "Edge Rate Limit by user-id request header with dictionaries"
  #   content = file("${path.module}/snippets/edge_rate_limiting_request_header_with_dictionary.vcl")
  #   type = "init"
  #   priority = 115
  # }

  ##### Rate limit by request header "user-id" and using ERL as state machine - Orange Gandolf
  snippet {
    name = "Edge Rate Limit State Machine"
    content = file("${path.module}/snippets/edge_rate_limiting_state_machine.vcl")
    type = "init"
    priority = 116
  }


  ##### origin_waf_response
  # snippet {
  #   name = "Origin Response Penalty Box"
  #   content = file("${path.module}/snippets/origin_response_penalty_box.vcl")
  #   type = "init"
  #   priority = 130
  # }
    
    ##### It is necessecary to disable caching for ERL to increment the counter for origin/backend requests
  snippet {
    name = "Disable caching"
    content = file("${path.module}/snippets/disable_caching.vcl")
    type = "recv"
    priority = 100
  }

  # dictionary {
  #   name       = "rl_user_agents"
  # }

  # dictionary {
  #   name       = "erl_config"
  # }

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



# resource "fastly_service_dictionary_items" "erl_config" {
#   for_each = {
#     for d in fastly_service_vcl.edge-rate-limiting-terraform-service.dictionary : d.name => d if d.name == "erl_config"
#   }
#   service_id = fastly_service_vcl.edge-rate-limiting-terraform-service.id
#   dictionary_id = each.value.dictionary_id
#   items = {
#     "blocking": "true",
#   }
#   manage_items = true
# }

output "live_laugh_love_edge_rate_limiting" {
  # How to test example
  value = <<tfmultiline

    #### Click the URL to go to the service ####
    https://cfg.fastly.com/${fastly_service_vcl.edge-rate-limiting-terraform-service.id}

    # The following commands are useful for testing.
    
    ## Rate Limit based on request header user-id
    siege "https://${var.USER_DOMAIN_NAME}/foo/v1/login" --header "user-id: 1" -t 5s

    # Run the following curl to send a request to the origin that will be tarpitted on the response
    curl -i https://erl-with-dictionaries.global.ssl.fastly.net/anything/123?x-obj-status=200 -H "http-me:1" -H "fastly-debug:1" -H "user-id: abc-1"

    
    echo "GET https://${var.USER_DOMAIN_NAME}/status?x-obj-status=200" | vegeta attack -header "user-id:abc-123" -duration=120s  | vegeta report -type=text
    
    # Navigate to the Domain Inspector UI
    https://manage.fastly.com/stats/real-time/services/${fastly_service_vcl.edge-rate-limiting-terraform-service.id}/datacenters/all/domains/

  tfmultiline
}
