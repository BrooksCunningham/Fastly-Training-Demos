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
    name = "fastly_http-me-compute_origin"
    port    = 443
    use_ssl = true
    ssl_cert_hostname = var.USER_DEFAULT_BACKEND_HOSTNAME
    ssl_sni_hostname = var.USER_DEFAULT_BACKEND_HOSTNAME
    override_host = var.USER_DEFAULT_BACKEND_HOSTNAME
  }

  snippet {
    name = "multi-snippet-and-rcs erl_init.vcl"
    content = file("${path.module}/vcl/multi-snippet-and-rcs/erl_init.vcl")
    type = "init"
    priority = 115
  }

  snippet {
    name = "multi-snippet-and-rcs erl_recv.vcl"
    content = file("${path.module}/vcl/multi-snippet-and-rcs/erl_recv.vcl")
    type = "recv"
    priority = 115
  }

  snippet {
    name = "multi-snippet-and-rcs erl_deliver.vcl"
    content = file("${path.module}/vcl/multi-snippet-and-rcs/erl_deliver.vcl")
    type = "deliver"
    priority = 115
  }

  snippet {
    name = "multi-snippet-and-rcs erl_error.vcl"
    content = file("${path.module}/vcl/multi-snippet-and-rcs/erl_error.vcl")
    type = "error"
    priority = 115
  }
 
  ##### It is necessecary to disable caching for ERL to increment the counter for origin/backend requests
  # snippet {
  #   name = "Disable caching"
  #   content = file("${path.module}/vcl/disable_caching.vcl")
  #   type = "recv"
  #   priority = 1000
  # }

    force_destroy = true
}

output "live_laugh_love_edge_rate_limiting" {
  # How to test example
  value = <<tfmultiline

    #### Click the URL to go to the service ####
    https://cfg.fastly.com/${fastly_service_vcl.edge-rate-limiting-terraform-service.id}

    # The following commands are useful for testing.
    
    ## Rate Limit based on request header user-id
    siege "https://${var.USER_DOMAIN_NAME}/anything/foo/v1/login" --header "user-id: 1" -t 5s

    ## Rate Limit based on URL
    siege "https://${var.USER_DOMAIN_NAME}/anything/foo/v1/menu/abc" -t 5s

    ## Add IP to Rate Limit Penalty box based on origin data
    echo "GET https://${var.USER_DOMAIN_NAME}/status/200" | vegeta attack -header "vegeta-test:ratelimittest1" -duration=30s  | vegeta report -type=text

    # Run the following curl and vegeta commands in a seperate adjacent windows with domain inspector to see the blocks in the Fastly UI.

    watch -n0.5 'curl -isD - -o /dev/null https://${var.USER_DOMAIN_NAME}/status/200 -H "fastly-debug:1" -H "user-id:xyz-123"'
    
    echo "GET https://${var.USER_DOMAIN_NAME}/status/200" | vegeta attack -header "user-id:abc-123" -duration=120s  | vegeta report -type=text
    
    # Navigate to the Domain Inspector UI
    https://manage.fastly.com/stats/real-time/services/${fastly_service_vcl.edge-rate-limiting-terraform-service.id}/datacenters/all/domains/

    curl -isD - -o /dev/null https://${var.USER_DOMAIN_NAME}/anything/en/robb -H "fastly-debug:1"

  tfmultiline
}
