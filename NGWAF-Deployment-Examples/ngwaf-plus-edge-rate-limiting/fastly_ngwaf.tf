# Try to follow recommended practices here, https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices
#### Supply NGWAF API authentication - Start
# environment variables must be available using "TF_VAR_*" in your terminal. 
# For example, `echo $TF_VAR_NGWAF_CORP` should return your intended corp.
provider "sigsci" {
  corp        = var.NGWAF_CORP
  email       = var.NGWAF_EMAIL
  auth_token  = var.NGWAF_TOKEN
}
#### Supply NGWAF API authentication - End

#### - Start
resource "sigsci_corp_rule" "edge-rate-limiting-corp-rule" {
  site_short_names = []
  type = "request"
  corp_scope = "global"
  enabled = true
  group_operator = "all"
  reason = "ERL Blocking Rule"
  expiration = ""



  conditions {
    field    = "path"
    type     = "single"
    operator = "contains"
    value = "/anything/erl"
  }
  conditions {
    field = "requestHeader"
    type = "multival"
    operator = "exists"
    group_operator = "all"
    conditions {
      type = "single"
      field = "name"
      operator = "equals"
      value = "X-Last-60s-Hits-default"
    }
    conditions {
      type = "single"
      field = "valueInt"
      operator = "greaterEqual"
      value = "5"
    }
  }
  
  # Easily enable/disable blocking by uncommenting/commenting the following action
  actions {
    type = "block"
  }
}
#### - End