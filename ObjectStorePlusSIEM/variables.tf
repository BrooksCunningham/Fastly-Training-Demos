# Fastly Edge VCL configuration
variable "FASTLY_API_KEY" {
    type        = string
    description = "This is API key for the Fastly VCL edge configuration."
}

#### Webhook Compute Service variables - Start
variable "WEBHOOK_SERVICE_DOMAIN_NAME" {
  type = string
  description = "Frontend domain for your service."
  default = "siem-webhook.global.ssl.fastly.net"
}

#### TODO - Add object store implementation

#### Webhook Compute Service variables - End


#### Basic Compute Service variables - Start
variable "BASIC_COMPUTE_SERVICE_DOMAIN_NAME" {
  type          = string
  description   = "Frontend domain for your service."
  default       = "siem-basic-compute.global.ssl.fastly.net"
}

variable "BASIC_COMPUTE_SERVICE_BACKEND_HOSTNAME" {
  type = string
  description = "hostname used for backend."
  default = "http-me.glitch.me"
}

#### Basic Compute Service variables - End



#### Artifacts
# https://status.demotool.site
# "info.demotool.site"
