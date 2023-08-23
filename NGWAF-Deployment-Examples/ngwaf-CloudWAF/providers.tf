# Configure the Fastly NGWAF Provider
provider "sigsci" {
  corp = var.NGWAF_CORP
  email = var.NGWAF_EMAIL
  auth_token = var.NGWAF_TOKEN
}

# Configure the Fastly Edge Provider
# provider "fastly" {
#   api_key = var.FASTLY_API_KEY
# }
