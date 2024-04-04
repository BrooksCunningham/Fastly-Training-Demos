# Work in progress

# Status = Not working



# Pre-reqs

* minikube
* kubectl
* container environment like colima
* docker-cli
* terraform

# What can go wrong?
Make sure the local image being built is accessible from the k8s environment. When working with minikube, I had to use the following command to make the locally built haproxy container accessible to my locally running k8s environment.

`eval $(minikube -p minikube docker-env)`



