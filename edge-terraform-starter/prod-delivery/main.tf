provider "sigsci" {
  corp       = var.NGWAF_CORP
  email      = var.NGWAF_EMAIL
  auth_token = var.NGWAF_TOKEN
  # alias      = "primary"
}

provider "fastly" {
  api_key = var.FASTLY_API_KEY
  # alias   = "primary"
}

module "service_vcl" {
  source                           = "../modules/service-vcl"
  FASTLY_API_KEY                   = var.FASTLY_API_KEY
  SERVICE_VCL_FRONTEND_DOMAIN_NAME = var.SERVICE_VCL_FRONTEND_DOMAIN_NAME
  SERVICE_VCL_BACKEND_HOSTNAME     = var.SERVICE_VCL_BACKEND_HOSTNAME
  NGWAF_SITE                       = var.NGWAF_SITE
  # NGWAF_EMAIL                      = var.NGWAF_EMAIL
  # NGWAF_TOKEN                      = var.NGWAF_TOKEN
  # NGWAF_CORP                       = var.NGWAF_CORP

  providers = {
    # fastly.primary = fastly.primary
    # sigsci.primary = sigsci.primary
    fastly = fastly
    sigsci = sigsci
  }
}
