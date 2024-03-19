# Fastly Edge VCL configuration
variable "FASTLY_API_KEY" {
  type        = string
  description = "This is API key for the Fastly VCL edge configuration."
}

#### VCL Service variables - Start
variable "SERVICE_VCL_FRONTEND_DOMAIN_NAME" {
  type        = string
  description = "Frontend domain for your service."
}

variable "SERVICE_VCL_BACKEND_HOSTNAME" {
  type        = string
  description = "hostname used for backend."
  default     = "http-me.edgecompute.app"
}

#### VCL Service variables - End

#### Compute Service variables - Start
# variable "SERVICE_COMPUTE_FRONTEND_DOMAIN_NAME" {
#   type = string
#   description = "Frontend domain for your service."
# }

# variable "SERVICE_COMPUTE_BACKEND_HOSTNAME" {
#   type          = string
#   description   = "hostname used for backend."
#   default       = "http-me.edgecompute.app"
# }

#### Compute Service variables - End

