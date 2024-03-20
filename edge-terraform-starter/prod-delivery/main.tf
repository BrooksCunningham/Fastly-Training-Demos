module "service_vcl" {
  source                           = "../modules/service-vcl"
  FASTLY_API_KEY                   = var.FASTLY_API_KEY
  SERVICE_VCL_FRONTEND_DOMAIN_NAME = var.SERVICE_VCL_FRONTEND_DOMAIN_NAME
  SERVICE_VCL_BACKEND_HOSTNAME     = var.SERVICE_VCL_BACKEND_HOSTNAME
  NGWAF_EMAIL                      = var.NGWAF_EMAIL
  NGWAF_TOKEN                      = var.NGWAF_TOKEN
  NGWAF_CORP                       = var.NGWAF_CORP
  NGWAF_SITE                       = var.NGWAF_SITE
}
