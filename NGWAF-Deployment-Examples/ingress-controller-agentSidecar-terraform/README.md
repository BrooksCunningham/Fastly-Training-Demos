## My implementation = not correctly deployed

# What remains?
The NGWAF NGWAF ingress module integration and the agent deployment.

# deploy.yaml taken from https://kubernetes.github.io/ingress-nginx/deploy/

Pre-reqs

Install minikube
Install kubectl
Install container environment like colima
Install docker-cli

# Troubleshooting

If you run into issues, then you will need to look at the `kubectl` documentation


For example
## Check th status of the ingress API and delete if needed.
* kubectl get validatingwebhookconfigurations,mutatingwebhookconfigurations -o name
* kubectl delete validatingwebhookconfigurations my-ingress-ingress-nginx-admission

## Minikube addons
Check that the ingress controller is enabled with minikube
* minikube addons list
* sudo minikube addons enable ingress
