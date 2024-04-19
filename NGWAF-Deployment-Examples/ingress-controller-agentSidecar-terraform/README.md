## My implementation = working


# The NGWAF NGWAF ingress module integration and the agent deployment.

# Pre-reqs

Install kind
Install kubectl
Install container environment like colima
Install docker-cli


# Quickstart
`make kindsetup`
`make build`
`make demo`

## Remove the setup
`make clean`

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


# What I have tried with sigsci_enabled

The following works without a defined location block
```
      server-snippet: |
      sigsci_enabled off;
```

Does not work to block requests
```
      server-snippet: |
        location = /apple/gprc {
          sigsci_enabled off;
          return 429;
        }
```

This does block requests
```
        location = /apple/z {
          return 429;
        }
```

Cannot use `sigsci_enabled` in an NGINX `if` block
```
if ($request_method = PUT ) {
    sigsci_enabled off;
}
```
