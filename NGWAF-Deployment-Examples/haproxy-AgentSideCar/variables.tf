#### NGWAF variables - Start

variable "NGWAF_ACCESSKEYID" {
  type          = string
  description   = "ACCESSKEYID name for NGWAF"
}

variable "NGWAF_ACCESSKEYSECRET" {
  type          = string
  description   = "SECRETACCESSKEY for NGWAF"
}

#### NGWAF variables - End

#### Docker variables - Start

variable "DOCKER_HOST" {
  type          = string
  description   = "DOCKER_HOST used for docker provider"
}

#### Docker variables - End

