# Fastly Edge configuration
variable "FASTLY_API_KEY" {
    type        = string
    description = "This is API key for the Fastly VCL edge configuration."
}

#### VCL Service variables - Start
variable "SERVICE_VCL_FRONTEND_DOMAIN_NAME" {
  type = string
  description = "Frontend domain for your service."
}

variable "SERVICE_VCL_BACKEND_HOSTNAME" {
  type          = string
  description   = "hostname used for backend."
  default       = "http-me.edgecompute.app"
}
#### VCL Service variables - End

#### Compute Service variables - Start
variable "SERVICE_COMPUTE_FRONTEND_DOMAIN_NAME" {
  type = string
  description = "Frontend domain for your service."
}

variable "SERVICE_COMPUTE_BACKEND_HOSTNAME" {
  type          = string
  description   = "hostname used for backend."
  default       = "http-me.edgecompute.app"
}
#### Compute Service variables - End

#### NGWAF variables - Start
variable "NGWAF_CORP" {
  type          = string
  description   = "Corp name for NGWAF"
}

variable "NGWAF_SITE" {
  type          = string
  description   = "Site name for NGWAF"
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
#### NGWAF variables - End

#### External Logging - Start
# variable "HONEYCOMB_API_KEY" {
#   # https://www.honeycomb.io/
#     type        = string
#     description = "Secret token for the Honeycomb API."
#     sensitive   = true
# }
#### External Logging - END