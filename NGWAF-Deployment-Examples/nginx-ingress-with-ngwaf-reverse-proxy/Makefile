KUBEDEPLOYMENT?=ngwaf-reverse-proxy
# KUBEYAML?=example-ingress.yaml
KUBEYAML?=nginx_ingress_with_reverse_proxy.yaml
# KUBEYAML?=nginx-deploy.yaml

# Environment variables $NGWAFACCESSKEYID and $NGWAFACCESSKEYSECRET must already be set before running `make build`
build:
	-@ kubectl create secret generic ngwaf-agent-keys --from-literal=accesskeyid=${NGWAFACCESSKEYID} --from-literal=secretaccesskey=${NGWAFACCESSKEYSECRET}
	kubectl apply -f $(KUBEYAML)
	-@ sleep 7
	-@ make demo


demo:
	kubectl get services
	echo "curl" `kubectl get services $(KUBEDEPLOYMENT)-lb | grep $(KUBEDEPLOYMENT) | awk '{print $$4}'`/anything/123
	curl `(minikube ip)`/anything/nginx-ingress-with-rev-proxy -i 
# curl $$(minikube service ngwaf-reverse-proxy-nodeport-service --url)/anything/hello-ngwaf

	
clean:
	- kubectl delete -f $(KUBEYAML)
	-@ sleep 3

describe:
	kubectl describe ingress
	kubectl describe services
	kubectl describe pods	

get:	
	kubectl get ingress
	kubectl get services
	kubectl get pods

rebuild:
	make clean; make build

exec:
	kubectl get pods | grep $(KUBEDEPLOYMENT) | awk '{print $$1}' | xargs -I {} echo kubectl exec --stdin --tty {} -- /bin/sh
# kubectl get pods | awk '{print $$1}' | xargs -I {} echo kubectl exec --stdin --tty {} -- /bin/sh
# kubectl get pods | grep $(KUBEDEPLOYMENT) | awk '{print $$1}' | xargs -I {} echo kubectl exec --stdin -c nginx --tty {} -- /bin/sh

# kubectl exec --stdin --tty ngwaf-revproxy-9b976bd75-mzwdh -- /bin/sh

# helpful command when troubleshooting kubectl secrets
# https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/
# kubectl get secrets
# kubectl describe secret ngwaf-agent-keys
# kubectl get secret ngwaf-agent-keys -o jsonpath='{.data}' | jq .accesskeyid -r | base64 -D
# kubectl delete secret ngwaf-agent-keys

logs:
	kubectl logs `kubectl get pods | tail -n +2 | awk '{print $$1}'` -c nginx
