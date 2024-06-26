# Fastly Edge VCL configuration
variable "FASTLY_API_KEY" {
    type        = string
    description = "This is API key for the Fastly VCL edge configuration."
}

#### VCL Service variables - Start
variable "USER_VCL_SERVICE_DOMAIN_NAME" {
  type = string
  description = "Frontend domain for your service."
}

variable "USER_VCL_SERVICE_BACKEND_HOSTNAME" {
  type          = string
  description   = "hostname used for backend."
  # default       = "http-me.glitch.me"
}

# Controls the percentage of traffic sent to NGWAF
variable "Edge_Security_dictionary" {
  type = string
  default = "Edge_Security"
}

#### VCL Service variables - End

#### Compute Service variables - Start
variable "USER_COMPUTE_SERVICE_DOMAIN_NAME" {
  type          = string
  description   = "Frontend domain for your service."
}

variable "USER_COMPUTE_SERVICE_BACKEND_HOSTNAME" {
  type = string
  description = "hostname used for backend."
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
