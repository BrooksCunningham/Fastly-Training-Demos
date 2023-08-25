# Fastly Delivery Provider
provider "fastly" {
  api_key = var.FASTLY_API_KEY
}

# Fastly NGWAF Provider
provider "sigsci" {
  corp = var.NGWAF_CORP
  email = var.NGWAF_EMAIL
  auth_token = var.NGWAF_TOKEN
  fastly_api_key = var.FASTLY_API_KEY
}
