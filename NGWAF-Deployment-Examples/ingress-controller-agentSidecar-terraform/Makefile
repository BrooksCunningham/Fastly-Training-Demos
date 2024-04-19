KUBEDEPLOYMENT?=nginx-ingress-controller-with-agent
KUBECTLFILE?=nginx_ingress_controller.yaml

# Environment variables $NGWAFACCESSKEYID and $NGWAFACCESSKEYSECRET must already be set before running `make build`
# https://kind.sigs.k8s.io/docs/user/ingress/#ingress-nginx



kindsetup:
	- kubectl cluster-info --context kind-kind
# kind does not have a native LB available. metallb may be used as a workaround
	- kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
# - kubectl apply -f https://kind.sigs.k8s.io/examples/loadbalancer/metallb-config.yaml
# local configuration is needed and maybe update the yaml. `docker network inspect -f '{{.IPAM.Config}}' kind`
	- kubectl apply -f ./metallb-config.yaml
	

setup:
#	- minikube addons enable ingress
	- docker pull signalsciences/sigsci-nginx-ingress-controller:1.10.0
	- docker pull signalsciences/sigsci-agent:latest
# - minikube image load signalsciences/sigsci-agent:latest
# - minikube image load signalsciences/sigsci-nginx-ingress-controller:1.10.0



build:
#	- kubectl apply -f controller_deploy.yaml
#	-@ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
#	-@ kubectl create secret generic ngwaf-agent-keys --from-literal=accesskeyid=${NGWAFACCESSKEYID} --from-literal=secretaccesskey=${NGWAFACCESSKEYSECRET}
#	# kubectl apply -f nginx_ingress_controller.yaml
	terraform apply -auto-approve -parallelism=1
	- make ihelm

ihelm:
	- helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# ingress controller is added to minikube via add-ons
	- helm install -n ingress-nginx -f values-sigsci.yaml ngwaf-ingress ingress-nginx/ingress-nginx

dhelm:
	- helm uninstall -n ingress-nginx ngwaf-ingress

demo:
#	kubectl get services
#	@echo "curl -H host:demo.localdev.me http://10.96.164.114/banana"
	@echo "curl -H host:demo.localdev.me http://`kubectl get services --namespace=ingress-nginx | grep LoadBalancer |awk '{print $$3}'`/apple ; curl -H host:demo.localdev.me http://`kubectl get services --namespace=ingress-nginx | grep LoadBalancer |awk '{print $$3}'`/banana"
	kubectl run curl-pod --image=appropriate/curl --rm -it -- sh
# echo "curl" `kubectl get services $(KUBEDEPLOYMENT)-lb | grep $(KUBEDEPLOYMENT) | awk '{print $$4}'`/anything/123
	
clean:
	- make dhelm
	- terraform destroy -auto-approve -parallelism=1
#	- kubectl delete validatingwebhookconfigurations my-ingress-ingress-nginx-admission
#	- kubectl delete -f controller_deploy.yaml
#	- kubectl delete -f nginx_ingress_controller.yaml
#	- kubectl delete ingressclass nginx


describe:
#	kubectl describe pods -A
	kubectl describe pods --namespace=ingress-nginx
#	kubectl describe ingress -A
	kubectl describe ingress --namespace=ingress-nginx

get:
#	- kubectl get services -A
	- kubectl get pods --namespace=ingress-nginx
	- kubectl get services --namespace=ingress-nginx
	- kubectl get ingress --namespace=ingress-nginx
# - kubectl get services $(KUBEDEPLOYMENT)-lb


rebuild:
	make clean; sleep 30; make build

ingressexec:
#	kubectl get pods --namespace=ingress-nginx | grep ingress-nginx-controller | awk '{print $$1}' | xargs -I {} echo kubectl exec --stdin --tty {} -c controller  -- /bin/sh
#kubectl get pods | grep $(KUBEDEPLOYMENT) | awk '{print $$1}' | xargs -I {} echo kubectl exec --stdin -c nginx --tty {} -- /bin/sh
	kubectl exec --namespace=ingress-nginx --stdin --tty `kubectl get pods --namespace=ingress-nginx | grep controller | awk '{print $$1}'` -c controller -- /bin/bash


# kubectl exec --stdin --tty ngwaf-revproxy-9b976bd75-mzwdh -- /bin/sh

# helpful command when troubleshooting kubectl secrets
# https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/
# kubectl get secrets
# kubectl describe secret ngwaf-agent-keys
# kubectl get secret ngwaf-agent-keys -o jsonpath='{.data}' | jq .accesskeyid -r | base64 -D
# kubectl delete secret ngwaf-agent-keys
