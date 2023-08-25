#### Fastly Compute@Edge Service - Start

data "fastly_package_hash" "example" {
  filename = null_resource.build_package.triggers.package_name
  depends_on = [ null_resource.build_package ]  
}

resource "fastly_service_compute" "compute-service-with-ngwaf" {
  name = "Compute Service with ngwaf - ${var.USER_COMPUTE_SERVICE_DOMAIN_NAME}"

  domain {
    name    = var.USER_COMPUTE_SERVICE_DOMAIN_NAME
    comment = "Compute@edge service"
  }

  package {
    filename         = data.local_file.package_name.filename
    source_code_hash = data.fastly_package_hash.example.hash
  }

  backend {
    address = var.USER_COMPUTE_SERVICE_BACKEND_HOSTNAME
    name = "httpme_origin"
    port    = 443
    use_ssl = true
    ssl_cert_hostname = var.USER_COMPUTE_SERVICE_BACKEND_HOSTNAME
    ssl_sni_hostname = var.USER_COMPUTE_SERVICE_BACKEND_HOSTNAME
    override_host = var.USER_COMPUTE_SERVICE_BACKEND_HOSTNAME
  }

  backend {
    address = var.USER_VCL_SERVICE_DOMAIN_NAME
    name = "ngwaf_origin"
    port    = 443
    use_ssl = true
    ssl_cert_hostname = var.USER_VCL_SERVICE_DOMAIN_NAME
    ssl_sni_hostname = var.USER_VCL_SERVICE_DOMAIN_NAME
    override_host = var.USER_VCL_SERVICE_DOMAIN_NAME
  }

  force_destroy = true
}

# https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource
resource "null_resource" "build_package" {
  triggers = {
    package_name = "${path.module}/compute-service-with-ngwaf/pkg/compute-service-with-ngwaf.tar.gz"
  }
  
  # https://www.terraform.io/docs/language/resources/provisioners/local-exec.html
  provisioner "local-exec" {
    command = "fastly compute build" 
    working_dir = "compute-service-with-ngwaf"
  }
}

# https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file
data "local_file" "package_name" {
  filename = null_resource.build_package.triggers.package_name
}

#### Fastly Compute@Edge Service - End


output "compute_live_waf_love_ngwaf_edge_deploy" {
  value = <<tfmultiline
  
  #### Click the URL to go to the Fastly Compute service ####
  https://cfg.fastly.com/${fastly_service_compute.compute-service-with-ngwaf.id}

  curl -i "https://${var.USER_COMPUTE_SERVICE_DOMAIN_NAME}/anything/whydopirates?likeurls=theargs" -d foo=bar

  #### Send an test as traversal with curl. ####
  curl -i "https://${var.USER_COMPUTE_SERVICE_DOMAIN_NAME}/anything/myattackreq?i=../../../../etc/passwd" -d foo=bar

  tfmultiline

  description = "Output hints on what to do next."

}
