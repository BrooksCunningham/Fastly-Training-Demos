## My implementation = working


# The NGWAF NGWAF ingress module integration and the agent deployment.

# Pre-reqs

Install kind
Install kubectl
Install container environment like colima
Install docker-cli

# Troubleshooting
* If you run into issues, then you will need to look at the `kubectl` documentation
* Make sure you are pulling the image into the minikube environment. https://minikube.sigs.k8s.io/docs/handbook/registry/


For example
## Check the status of the ingress API and delete if needed.
* kubectl get validatingwebhookconfigurations,mutatingwebhookconfigurations -o name
* kubectl delete validatingwebhookconfigurations my-ingress-ingress-nginx-admission

## Minikube addons
Check that the ingress controller is enabled with minikube
* minikube addons list
* sudo minikube addons enable ingress


# Common Errors
```
helm install -n ingress-nginx -f values-sigsci.yaml my-ingress ingress-nginx/ingress-nginx
Error: INSTALLATION FAILED: Unable to continue with install: IngressClass "nginx" in namespace "" exists and cannot be imported into the current release: invalid ownership metadata; label validation error: missing key "app.kubernetes.io/managed-by": must be set to "Helm"; annotation validation error: missing key "meta.helm.sh/release-name": must be set to "my-ingress"; annotation validation error: missing key "meta.helm.sh/release-namespace": must be set to "ingress-nginx"
```
Here is the fix
```
! kubectl describe ingressclasses
Name:         nginx
Labels:       app.kubernetes.io/component=controller
              app.kubernetes.io/instance=ingress-nginx
              app.kubernetes.io/name=ingress-nginx
Annotations:  ingressclass.kubernetes.io/is-default-class: true
Controller:   k8s.io/ingress-nginx
Events:       <none>
```
```
! kubectl delete ingressclasses  nginx
ingressclass.networking.k8s.io "nginx" deleted
```
