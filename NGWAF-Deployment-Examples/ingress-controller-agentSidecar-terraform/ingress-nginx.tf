
provider "kubernetes" {
  # Assuming you have a kubeconfig file that points to your Kubernetes cluster
  config_path = "~/.kube/config"
}

# provider "helm" {
#   kubernetes {
#     config_path = "~/.kube/config"
#   }
# }

# resource "helm_release" "example" {
#   name       = "helm-release-example"
#   namespace = kubernetes_namespace.example.metadata[0].name
#   chart      = "ingress-nginx"
#   repository = "https://kubernetes.github.io/ingress-nginx"

#   set {
#     name  = "service.type"
#     value = "ClusterIP"
#   }
#   # values = [
#   #   file("${path.module}/values-sigsci.yaml")
#   # ]
#   timeout = 60
# }


# https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/
resource "kubernetes_namespace" "example" {
  metadata {
    annotations = {
      name = "example-annotation"
    }

    labels = {
      mylabel = "label-value"
    }

    name = "ingress-nginx"
  }
}

resource "kubernetes_ingress_v1" "example" {
  metadata {
    name      = "example-nginx-ingress"
    # namespace = "ingress-nginx"
    namespace = kubernetes_namespace.example.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "demo.localdev.me"
      http {
        path {
          path      = "/apple"
          path_type = "Prefix"
          backend {
            service {
              name = "apple-service"
              port {
                number = 5678
              }
            }
          }
        }
        path {
          path      = "/banana"
          path_type = "Prefix"
          backend {
            service {
              name = "banana-service"
              port {
                number = 5678
              }
            }
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_service.banana_service,
    kubernetes_service.apple_service,
  ]
  timeouts {
    create = "1m"
    delete = "1m"  
  }
}

resource "kubernetes_ingress_v1" "example-no-waf" {
  metadata {
    name      = "nosigsci-nginx-ingress"
    # namespace = "ingress-nginx"
    namespace = kubernetes_namespace.example.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "nginx.ingress.kubernetes.io/configuration-snippet" = <<multiline
        sigsci_enabled off;
        multiline
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "demo.localdev.me"
      http {
        path {
          path      = "/apple/nowaf"
          path_type = "Prefix"
          backend {
            service {
              name = "apple-service"
              port {
                number = 5678
              }
            }
          }
        }
        path {
          path      = "/banana/nowaf"
          path_type = "Prefix"
          backend {
            service {
              name = "banana-service"
              port {
                number = 5678
              }
            }
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_service.banana_service,
    kubernetes_service.apple_service,
  ]
  timeouts {
    create = "1m"
    delete = "1m"  
  }
}

resource "kubernetes_pod" "banana_app" {
  metadata {
    name      = "banana-app"
    # namespace = "ingress-nginx"
    namespace = kubernetes_namespace.example.metadata[0].name
    labels = {
      app = "banana"
    }
  }

  spec {
    container {
      name  = "banana-app"
      image = "hashicorp/http-echo"
      args  = ["-text=banana"]
    }
  }
}

resource "kubernetes_pod" "apple_app" {
  metadata {
    name      = "apple-app"
    # namespace = "ingress-nginx"
    namespace = kubernetes_namespace.example.metadata[0].name
    labels = {
      app = "apple"
    }
  }

  spec {
    container {
      name  = "apple-app"
      image = "hashicorp/http-echo"
      args  = ["-text=apple"]
    }
  }
}

resource "kubernetes_secret" "example" {
  metadata {
    name = "ngwaf-agent-config"
    # namespace = "ingress-nginx"
    namespace = kubernetes_namespace.example.metadata[0].name
  }

  data = {
    accesskeyid     = var.NGWAF_ACCESSKEYID
    secretaccesskey = var.NGWAF_ACCESSKEYSECRET
    # revproxylister  = "listen_conf:{listener=http://0.0.0.0:80,upstreams=https://http-me.edgecompute.app:443,access-log='/dev/stdout',pass-host-header=false}"
  }
}


resource "kubernetes_service" "banana_service" {
  metadata {
    name      = "banana-service"
    namespace = "ingress-nginx"
    # namespace = kubernetes_namespace.example.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_pod.banana_app.metadata[0].labels.app
    }
    port {
      port = 5678
    }
  }

  depends_on = [kubernetes_pod.banana_app]
}

resource "kubernetes_service" "apple_service" {
  metadata {
    name      = "apple-service"
    # namespace = "ingress-nginx"
    namespace = kubernetes_namespace.example.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_pod.apple_app.metadata[0].labels.app
    }
    port {
      port = 5678
    }
  }
}

# resource "kubernetes_service" "nginx_ingress_nodeport" {
#   metadata {
#     name      = "nginx-ingress-nodeport"
#     # namespace = "ingress-nginx"
#     namespace = kubernetes_namespace.example.metadata[0].name
#   }
#   spec {
#     selector = {
#       name    = "ingress-nginx"
#       instance = "ingress-nginx"
#     }
#     port {
#       name        = "http"
#       protocol    = "TCP"
#       port        = 80
#       target_port = 80
#       node_port   = 30080
#     }

#     type = "NodePort"
#   }
# }


output "k8s_output" {
  value = <<tfmultiline

    #### troubleshooting
    kubectl describe deployments
    kubectl describe pod 
    kubectl logs `kubectl get pods -n ingress-nginx | awk '{print $1}' | tail -n1` -n ingress-nginx -c sigsci-agent

    kubectl get validatingwebhookconfigurations,mutatingwebhookconfigurations -o name

    #### cleanup
    kubectl delete secrets ngwaf-agent-config
    kubectl delete ns ngwaf-rev-proxy

    #### Testing
    curl -H 'host:demo.localdev.me' http://`kubectl get ingress -n ingress-nginx | awk '{print $4}' | tail -n1`/apple
    curl -H 'host:demo.localdev.me' http://`kubectl get ingress -n ingress-nginx | awk '{print $4}' | tail -n1`/banana

    tfmultiline

  #     curl "http://`minikube ip`:${kubernetes_service.example.spec[0].port[0].node_port}/anything/123"

}
