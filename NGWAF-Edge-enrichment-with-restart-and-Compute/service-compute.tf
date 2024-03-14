#### Fastly Compute@Edge Service - Start

data "fastly_package_hash" "example" {
  filename = null_resource.build_package.triggers.package_name
  depends_on = [ null_resource.build_package ]  
} 

resource "fastly_service_compute" "package" {
  name = "Compute Service Client ID Check - ${var.SERVICE_COMPUTE_FRONTEND_DOMAIN_NAME}"

  domain {
    name    = var.SERVICE_COMPUTE_FRONTEND_DOMAIN_NAME
    comment = "Service compute@edge"
  }

  package {
    filename         = data.local_file.package_name.filename
    source_code_hash = data.fastly_package_hash.example.hash
  }

  force_destroy = true
}

# https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource
resource "null_resource" "build_package" {
  triggers = {
    package_name = "${path.module}/service-compute/pkg/package.tar.gz"
  }
  
  # https://www.terraform.io/docs/language/resources/provisioners/local-exec.html
  provisioner "local-exec" {
    command = "fastly compute build --package-name=package" 
    working_dir = "${path.module}/service-compute"
  }
}

# https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file
data "local_file" "package_name" {
  filename = null_resource.build_package.triggers.package_name
}

#### Fastly Compute@Edge Service - End
