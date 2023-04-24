
# Environment variables $NGWAFACCESSKEYID and $NGWAFACCESSKEYSECRET must already be set before running `make build`
build:
	kubectl create secret generic ngwaf-agent-keys --from-literal=accesskeyid=${NGWAFACCESSKEYID} --from-literal=secretaccesskey=${NGWAFACCESSKEYSECRET}
	kubectl apply -f rev_proxy.yaml
	echo "Run the command `minikube tunnel` command. Then run `make demo` in a seperate terminal to see how to test locally.""

#minikube tunnel

demo:
	kubectl get services
	echo "now curl to the external IP"
	
clean:
	kubectl get deployments --all-namespaces
	kubectl delete -n default deployment ngwaf-revproxy
	kubectl delete services ngwaf-revproxy-lb
	kubectl delete secret ngwaf-agent-keys

rebuild:
	make clean; make build

make exec:
	kubectl get pods
# kubectl exec --stdin --tty ngwaf-revproxy-9b976bd75-mzwdh -- /bin/sh

# helpful command when troubleshooting kubectl secrets
# https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/
# kubectl get secrets
# kubectl describe secret ngwaf-agent-keys
# kubectl get secret ngwaf-agent-keys -o jsonpath='{.data}' | jq .accesskeyid -r | base64 -D
# kubectl delete secret ngwaf-agent-keys
