# Configure the Fastly Provider
provider "fastly" {
  api_key = var.FASTLY_API_KEY
}


# terraform import fastly_service_vcl.demo xxxxxxxxxxxxxxxxxxxx

#### Webhook Compute@Edge Service - Start

resource "fastly_service_compute" "compute_webhook_service" {
  name = "Webhook Compute Receiver with object store"

  domain {
    name    = var.WEBHOOK_SERVICE_DOMAIN_NAME
    comment = "Webhook Compute Receiver with object store"
  }

  package {
    filename         = data.local_file.package_name_compute_webhook_receiver.filename
    source_code_hash = sha512(data.local_file.package_name_compute_webhook_receiver.content)
  }

  # if I was just working with a standard pre-built package (i.e. a package I manually compiled) I'd use...
  #
  # filename         = "package-built-locally-via-cli.tar.gz"
  # source_code_hash = filesha512("package-built-locally-via-cli.tar.gz")

  force_destroy = true
}

# https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource
resource "null_resource" "build_package_compute_webhook_receiver" {
  triggers = {
    package_name = "${path.module}/compute-webhook-receiver/pkg/package.tar.gz"
  }
  
  # https://www.terraform.io/docs/language/resources/provisioners/local-exec.html
  provisioner "local-exec" {
    command = "fastly compute build --package-name=package" 
    working_dir = "compute-webhook-receiver"
  }
}

# https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file
data "local_file" "package_name_compute_webhook_receiver" {
  filename = null_resource.build_package_compute_webhook_receiver.triggers.package_name
}
#### Webhook Compute@Edge Service - End

#### Basic Compute@Edge Service - Start

resource "fastly_service_compute" "compute_basic_service" {
  name = "Basic compute service with Object Store"

  domain {
    name    = var.BASIC_COMPUTE_SERVICE_DOMAIN_NAME
    comment = "Basic compute service with Object Store"
  }

  package {
    filename         = data.local_file.package_name_compute_basic_service.filename
    source_code_hash = sha512(data.local_file.package_name_compute_basic_service.content)
  }

  # if I was just working with a standard pre-built package (i.e. a package I manually compiled) I'd use...
  #
  # filename         = "package-built-locally-via-cli.tar.gz"
  # source_code_hash = filesha512("package-built-locally-via-cli.tar.gz")

  backend {
    address = var.BASIC_COMPUTE_SERVICE_BACKEND_HOSTNAME
    name = "compute_origin_0"
    port    = 443
    use_ssl = true
    ssl_cert_hostname = var.BASIC_COMPUTE_SERVICE_BACKEND_HOSTNAME
    ssl_sni_hostname = var.BASIC_COMPUTE_SERVICE_BACKEND_HOSTNAME
    override_host = var.BASIC_COMPUTE_SERVICE_BACKEND_HOSTNAME
  }


  lifecycle {
    ignore_changes = [
      product_enablement,
    ]
  }

  #### TODO Add link to object store once there is support

  force_destroy = true
}

# https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource
resource "null_resource" "build_package_compute_basic_service" {
  triggers = {
    package_name = "${path.module}/compute-basic-service/pkg/package.tar.gz"
  }
  
  # https://www.terraform.io/docs/language/resources/provisioners/local-exec.html
  provisioner "local-exec" {
    command = "fastly compute build --package-name=package" 
    working_dir = "compute-basic-service"
  }
}

# https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file
data "local_file" "package_name_compute_basic_service" {
  filename = null_resource.build_package_compute_basic_service.triggers.package_name
}

#### Basic Compute@Edge Service - End

### Need to create object store and link manually
# https://developer.fastly.com/reference/api/services/resources/object-store/#create-store

