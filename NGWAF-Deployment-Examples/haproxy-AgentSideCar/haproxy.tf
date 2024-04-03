provider "kubernetes" {
  # Assuming you have a kubeconfig file that points to your Kubernetes cluster
  config_path = "~/.kube/config"
}

resource "kubernetes_config_map" "haproxy_cfg" {
  metadata {
    name = "haproxy-config"
  }

  data = {
    "haproxy.cfg" = <<-EOT
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
          image = "haproxy:latest"
          name  = "haproxy"

          volume_mount {
            name       = "config"
            mount_path = "/usr/local/etc/haproxy"
          }

          port {
            container_port = 80
          }
        }

        volume {
          name = "config"

          config_map {
            name = kubernetes_config_map.haproxy_cfg.metadata[0].name
            default_mode = "0644"
            items {
              key  = "haproxy.cfg"
              path = "haproxy.cfg"
            }
          }
        }
      }
    }
  }
}

# resource "kubernetes_service" "haproxy" {
#   metadata {
#     name = "haproxy"
#   }

#   spec {
#     selector = {
#       app = "haproxy"
#     }

#     port {
#       port        = 80
#       target_port = 80
#     }

#     type = "LoadBalancer"
#   }
# }

resource "kubernetes_service" "example" {
  metadata {
    name      = "haproxy"
  }
  spec {
    selector = {
    #   app = kubernetes_deployment.example.spec.0.template.0.metadata.0.labels.app
    #   app = kubernetes_service.haproxy.spec.0.template.0.metadata.0.labels.app
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