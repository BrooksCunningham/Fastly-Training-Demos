terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}
