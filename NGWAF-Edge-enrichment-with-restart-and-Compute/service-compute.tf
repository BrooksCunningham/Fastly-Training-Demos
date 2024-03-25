#### Fastly Compute@Edge Service - Start


# https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource
resource "null_resource" "build_package" {
  triggers = {
    package_name = "${path.module}/service-compute/pkg/package.tar.gz"
    always_run   = "${timestamp()}"
  }

  # https://www.terraform.io/docs/language/resources/provisioners/local-exec.html
  provisioner "local-exec" {
    command     = "fastly compute build --package-name=package"
    working_dir = "${path.module}/service-compute"
  }
}

# https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file
data "local_file" "package_name" {
  filename = null_resource.build_package.triggers.package_name
  # depends_on = [null_resource.build_package]
}

data "fastly_package_hash" "compute_package_hash" {
  filename = null_resource.build_package.triggers.package_name
  # depends_on = [null_resource.build_package]
}

resource "fastly_service_compute" "compute_service" {
  name = var.SERVICE_COMPUTE_FRONTEND_DOMAIN_NAME

  domain {
    name    = var.SERVICE_COMPUTE_FRONTEND_DOMAIN_NAME
    comment = "Service compute@edge"
  }

  package {
    filename         = data.local_file.package_name.filename
    source_code_hash = data.fastly_package_hash.compute_package_hash.hash
  }

  resource_link {
    name        = "ip_blocklist"
    resource_id = fastly_kvstore.ip_blocklist_store.id
  }

  force_destroy = true

  depends_on = [null_resource.build_package]
}

#### Fastly Compute@Edge Service - End

resource "fastly_kvstore" "ip_blocklist_store" {
  name          = "ip_blocklist_store"
  force_destroy = true
}

output "compute-service-output" {
  value = <<tfmultiline
  #### Click the URL to go to the Fastly Compute service ####
  https://cfg.fastly.com/${fastly_service_compute.compute_service.id}

  #### Test
  curl https://${var.SERVICE_COMPUTE_FRONTEND_DOMAIN_NAME}/get -H fastly-debug:10145-bdn -d foo

  #### Add entry
  curl --data @./service-compute/payload.json "https://${var.SERVICE_COMPUTE_FRONTEND_DOMAIN_NAME}/add"

  #### tail logs
  fastly log-tail -s ${fastly_service_compute.compute_service.id}

  tfmultiline
}
