KUBEDEPLOYMENT?=ngwaf-revproxy

# Environment variables $NGWAFACCESSKEYID and $NGWAFACCESSKEYSECRET must already be set before running `make build`
build:
	echo "Make sure your container environment such as colima and minikube are running."
	-@ kubectl create secret generic ngwaf-agent-keys --from-literal=accesskeyid=${NGWAFACCESSKEYID} --from-literal=secretaccesskey=${NGWAFACCESSKEYSECRET}
	kubectl apply -f rev_proxy.yaml
	echo "Run the command minikube tunnel command. Then run make demo in a seperate terminal to see how to test locally."
	sleep 5
	make demo

#minikube tunnel

demo:
	kubectl get services
	echo "curl" `kubectl get services $(KUBEDEPLOYMENT)-lb | grep $(KUBEDEPLOYMENT) | awk '{print $$4}'`/anything/123
	
clean:
	kubectl get deployments
	- kubectl get deployment $(KUBEDEPLOYMENT) | awk '{print $$1}' | xargs kubectl delete deployment
	- kubectl get services $(KUBEDEPLOYMENT)-lb | awk '{print $$1}' | xargs kubectl delete services
	- kubectl delete secret ngwaf-agent-keys
	
describe:
	kubectl describe pods	

get:
	- kubectl get 
	- kubectl get services


rebuild:
	make clean; make build

make exec:
	kubectl get pods | grep $(KUBEDEPLOYMENT) | awk '{print $$1}' | xargs -I {} echo kubectl exec --stdin --tty {} -- /bin/sh

# kubectl exec --stdin --tty ngwaf-revproxy-9b976bd75-mzwdh -- /bin/sh

# helpful command when troubleshooting kubectl secrets
# https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/
# kubectl get secrets
# kubectl describe secret ngwaf-agent-keys
# kubectl get secret ngwaf-agent-keys -o jsonpath='{.data}' | jq .accesskeyid -r | base64 -D
# kubectl delete secret ngwaf-agent-keys
