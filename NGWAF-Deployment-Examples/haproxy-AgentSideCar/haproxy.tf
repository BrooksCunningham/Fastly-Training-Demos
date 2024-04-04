provider "docker" {
  host = "tcp://192.168.64.4:2376"

  # registry_auth {
  #   config_file = "~/.docker/config.json"
  # }
}

# make a registry
# https://stackoverflow.com/questions/57167104/how-to-use-local-docker-image-in-kubernetes-via-kubectl
# docker run -d -p 5000:5000 --restart=always --name registry registry:2
# Build the image
# docker build . -t localhost:5000/local-registry/haproxy-ngwaf-module:latest
# docker build . -t mylocaltrainingimages/haproxy-ngwaf-module
#### Push the image to the local registry
# docker push localhost:5000/local-registry/haproxy-ngwaf-module
#### check images
# docker image list local-registry/haproxy-ngwaf-module:latest


# Create a container
resource "docker_image" "example_image" {
  name = "local-registry/haproxy-ngwaf-module"
  build {
    context = "."
    tag     = ["latest"]
    label = {
      author : "Brooks"
    }
  }
  # keep_locally = true # Do not delete the image from the local Docker registry after Terraform apply
  triggers = {
    always_run = "${timestamp()}"
  }
  # docker build -t mylocaltrainingimages/haproxy-ngwaf-module .
}

provider "kubernetes" {
  # Assuming you have a kubeconfig file that points to your Kubernetes cluster
  config_path = "~/.kube/config"
}

resource "kubernetes_config_map" "haproxy_cfg" {
  metadata {
    name = "haproxy-config"
  }

  data = {
    "haproxy.cfg" = <<EOT
      global
        log stdout format raw local0

      defaults
        log     global
        mode    http
        option  httplog
        timeout connect 5000ms
        timeout client  50000ms
        timeout server  50000ms

      frontend http_front
        bind *:80
        stats uri /haproxy?stats
        default_backend http_back

      backend http_back
        http-request set-header Host http.edgecompute.app
        server edge http.edgecompute.app:443 ssl verify none
    EOT
  }
}

resource "kubernetes_deployment" "haproxy" {
  metadata {
    name = "haproxy"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "haproxy"
      }
    }

    template {
      metadata {
        labels = {
          app = "haproxy"
        }
      }

      spec {
        container {
          image             = docker_image.example_image.name # "mylocaltrainingimages/haproxy-ngwaf-module"
          name              = "haproxy"
          image_pull_policy = "IfNotPresent"

          volume_mount {
            name       = "haproxy-config"
            mount_path = "/usr/local/etc/haproxy"
          }

          port {
            container_port = 80
          }
        }
        container {
          name              = "fastly-ngwaf-agent"
          image             = "signalsciences/sigsci-agent:latest"
          image_pull_policy = "IfNotPresent"
          env {
            name = "SIGSCI_ACCESSKEYID"
            value_from {
              secret_key_ref {
                name = "ngwaf-agent-config"
                key  = "accesskeyid"
              }
            }
          }
          env {
            name = "SIGSCI_SECRETACCESSKEY"
            value_from {
              secret_key_ref {
                name = "ngwaf-agent-config"
                key  = "secretaccesskey"
              }
            }
          }
          env {
            name  = "SIGSCI_HAPROXY_SPOA_ENABLED"
            value = "true"
          }
          # env {
          #   name  = "SIGSCI_HAPROXY_SPOA_ADDRESS"  # haproxy-spoa-address
          #   value = "unix:/sigsci/tmp/sigsci-ha.sock"
          #   # value = "unix:/var/run/sigsci-ha.sock"
          # }
        }

        volume {
          name = "haproxy-config"

          config_map {
            name         = kubernetes_config_map.haproxy_cfg.metadata[0].name
            default_mode = "0644"
            items {
              key  = "haproxy.cfg"
              path = "haproxy.cfg"
            }
          }
        }
        volume {
          name = "ngwaf-tmp"
          empty_dir {}
        }
      }
    }
  }
  timeouts {
    create = "1m"
    delete = "1m"
    update = "1m"
  }
}

# --env SIGSCI_HAPROXY_SPOA_ENABLED="true"
# --env SIGSCI_RPC_ADDRESS="unix:/var/run/sigsci-ha.sock"

resource "kubernetes_service" "example" {
  metadata {
    name = "haproxy"
  }
  spec {
    selector = {
      app = kubernetes_deployment.haproxy.spec.0.template.0.metadata.0.labels.app
    }
    type = "NodePort"
    port {
      node_port   = 30211
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_secret" "example" {
  metadata {
    name = "ngwaf-agent-config"
  }

  data = {
    accesskeyid     = var.NGWAF_ACCESSKEYID
    secretaccesskey = var.NGWAF_ACCESSKEYSECRET
    # revproxylister  = "listen_conf:{listener=http://0.0.0.0:80,upstreams=https://http-me.edgecompute.app:443,access-log='/dev/stdout',pass-host-header=false}"
  }
}

output "k8s_output" {
  value = <<tfmultiline

    #### troubleshooting
    kubectl describe deployments
    kubectl describe pod ngwaf-rev-proxy-7584f87b6f-4s528
    kubectl logs `kubectl get pods | awk '{print $1}' | tail -n1` -c fastly-ngwaf-agent

    #### cleanup
    kubectl delete secrets ngwaf-agent-config
    kubectl delete ns ngwaf-rev-proxy

    curl "http://`minikube ip`:${kubernetes_service.example.spec[0].port[0].node_port}/anything/123"

    tfmultiline

}
