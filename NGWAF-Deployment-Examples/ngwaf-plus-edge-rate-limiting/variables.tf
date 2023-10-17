#### variables for the initial provider setup
variable "NGWAF_CORP" {
    type        = string
    description = "NGWAF Corp where configuration changes will be made."
}
variable "NGWAF_SITE" {
    type        = string
    description = "NGWAF Site where configuration changes will be made."
}
variable "NGWAF_EMAIL" {
    type        = string
    description = "Email address associated with the token for the NGWAF API."
}
variable "NGWAF_TOKEN" {
    type        = string
    description = "Secret token for the NGWAF API."
    sensitive   = true
}

# Fastly Edge variables
variable "FASTLY_API_KEY" {
    type        = string
    description = "This is API key for the Fastly VCL edge configuration."
}

variable "USER_VCL_SERVICE_DOMAIN_NAME" {
  type = string
  description = "Frontend domain for your service."
  default = "ngwaf-plus-erl-demo.global.ssl.fastly.net"
}

variable "USER_VCL_SERVICE_BACKEND_HOSTNAME" {
  type = string
  description = "Backend for your service."
  default = "http-me.edgecompute.app"
  # default = "https://info.demotool.site/"
}
