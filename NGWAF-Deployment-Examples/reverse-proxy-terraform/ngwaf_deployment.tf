provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_deployment" "example" {
  metadata {
    name      = "ngwaf-rev-proxy"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "MyTestApp"
      }
    }
    template {
      metadata {
        labels = {
          app = "MyTestApp"
          name = "ngwaf-rev-proxy"
        }
      }
      spec {
        container {
          name              = "fastly-ngwaf-agent"
          image             = "signalsciences/sigsci-agent:latest"
          image_pull_policy = "IfNotPresent"
          port {
            container_port = 80
          }
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
            name = "SIGSCI_REVPROXY_LISTENER"
            value = kubernetes_secret.example.data["revproxylister"]
          }
        }
      }
    }
  }
}
resource "kubernetes_service" "example" {
  metadata {
    name      = "ngwaf-rev-proxy"
  }
  spec {
    selector = {
      app = kubernetes_deployment.example.spec.0.template.0.metadata.0.labels.app
    }
    type = "NodePort"
    port {
      node_port   = 30201
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
    revproxylister  = "listen_conf:{listener=http://0.0.0.0:80,upstreams=https://http-me.edgecompute.app:443,access-log='/dev/stdout',pass-host-header=false}"
  }
}

output "k8s_output" {
  value = <<tfmultiline

    curl `minikube ip`:${kubernetes_service.example.spec[0].port[0].node_port}/anything/abc | jq

    #### troubleshooting
    kubectl describe deployments -n ngwaf-rev-proxy
    kubectl describe pod ngwaf-rev-proxy-7584f87b6f-4s528 -n ngwaf-rev-proxy
    kubectl logs `kubectl get pods | awk '{print $1}' | tail -n1` -c fastly-ngwaf-agent

    #### cleanup
    kubectl delete secrets ngwaf-agent-config
    kubectl delete ns ngwaf-rev-proxy

    tfmultiline

}
