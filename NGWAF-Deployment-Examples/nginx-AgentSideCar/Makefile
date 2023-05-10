KUBEDEPLOYMENT?=nginx-module-with-ngwaf-sidecar

# Environment variables $NGWAFACCESSKEYID and $NGWAFACCESSKEYSECRET must already be set before running `make build`
build:
	- docker build . -t bcunningham/nginx-module
	-@ kubectl create secret generic ngwaf-agent-keys --from-literal=accesskeyid=${NGWAFACCESSKEYID} --from-literal=secretaccesskey=${NGWAFACCESSKEYSECRET}
	kubectl apply -f nginx_sidecar.yaml
	echo "Run the command minikube tunnel command. Then run make demo in a seperate terminal to see how to test locally."

#minikube tunnel

demo:
	kubectl get services
	echo "curl" `kubectl get services $(KUBEDEPLOYMENT)-lb | grep $(KUBEDEPLOYMENT) | awk '{print $$4}'`/anything/123
	
clean:
	- kubectl delete -f nginx_sidecar.yaml
	sleep 3
	- docker image rm bcunningham/nginx-module
# kubectl get deployments
# - kubectl get deployment $(KUBEDEPLOYMENT) | awk '{print $$1}' | xargs kubectl delete deployment
# - kubectl get services $(KUBEDEPLOYMENT)-lb | awk '{print $$1}' | xargs kubectl delete services
# - kubectl delete secret ngwaf-agent-keys

describe:
	kubectl describe pods	

get:
	- kubectl get 
	- kubectl get services
# - kubectl get services $(KUBEDEPLOYMENT)-lb


rebuild:
	make clean; make build

make exec:
	kubectl get pods | grep $(KUBEDEPLOYMENT) | awk '{print $$1}' | xargs -I {} echo kubectl exec --stdin --tty {} -- /bin/sh
	kubectl get pods | grep $(KUBEDEPLOYMENT) | awk '{print $$1}' | xargs -I {} echo kubectl exec --stdin -c nginx --tty {} -- /bin/sh

# kubectl exec --stdin --tty ngwaf-revproxy-9b976bd75-mzwdh -- /bin/sh

# helpful command when troubleshooting kubectl secrets
# https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/
# kubectl get secrets
# kubectl describe secret ngwaf-agent-keys
# kubectl get secret ngwaf-agent-keys -o jsonpath='{.data}' | jq .accesskeyid -r | base64 -D
# kubectl delete secret ngwaf-agent-keys
