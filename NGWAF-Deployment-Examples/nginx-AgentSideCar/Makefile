KUBEDEPLOYMENT?=nginx-module-with-ngwaf-sidecar
KUBEYAML?=nginx_sidecar.yaml
CONTAINERNAME?=mylocaltrainingimages/nginx-module
# CONTAINERNAME?=127.0.0.1:5000/local-nginx-module
# KUBEYAML?=nginx-deploy.yaml

# Environment variables $NGWAFACCESSKEYID and $NGWAFACCESSKEYSECRET must already be set before running `make build`
# make sure that you are running kind and load the image into kind
build:
	- docker build . -t $(CONTAINERNAME)
# - docker push $(CONTAINERNAME)
	- kind load docker-image $(CONTAINERNAME)
	-@ kubectl create secret generic ngwaf-agent-keys --from-literal=accesskeyid=${NGWAFACCESSKEYID} --from-literal=secretaccesskey=${NGWAFACCESSKEYSECRET}
	kubectl apply -f $(KUBEYAML)
	-@ sleep 5
#	-@ make demo

kbuild:
	kubectl apply -f $(KUBEYAML)
	-@ sleep 5

kclean:
	- kubectl delete -f $(KUBEYAML)

krebuild:
	make kclean
	sleep 5
	make kbuild


demo:
	kubectl get services
	echo "curl" `kubectl get services $(KUBEDEPLOYMENT)-lb | grep $(KUBEDEPLOYMENT) | awk '{print $$4}'`/anything/123
	kubectl run curl-pod --image=appropriate/curl --rm -it -- sh

# kubectl run nginx-module-pod --image=mylocaltrainingimages/nginx-module --rm -it -- sh 

clean:
	- kubectl delete -f $(KUBEYAML)
	sleep 3
	- docker image rm $(CONTAINERNAME)
# - docker image rm 127.0.0.1:5000/local-nginx-module
# kubectl get deployments
# - kubectl get deployment $(KUBEDEPLOYMENT) | awk '{print $$1}' | xargs kubectl delete deployment
# - kubectl get services $(KUBEDEPLOYMENT)-lb | awk '{print $$1}' | xargs kubectl delete services
# - kubectl delete secret ngwaf-agent-keys

describe:
	kubectl describe pods	
	kubectl describe services

get:	
	- kubectl get pods
	- kubectl get services
# - kubectl get services $(KUBEDEPLOYMENT)-lb


rebuild:
	make clean; make build

exec:
# kubectl get pods | grep $(KUBEDEPLOYMENT) | awk '{print $$1}' | xargs -I {} echo kubectl exec --stdin --tty {} -- /bin/sh
# kubectl get pods | awk '{print $$1}' | xargs -I {} echo kubectl exec --stdin --tty {} -- /bin/sh
	kubectl get pods | grep $(KUBEDEPLOYMENT) | awk '{print $$1}' | xargs -I {} echo kubectl exec --stdin -c nginx --tty {} -- /bin/sh

# kubectl exec --stdin --tty ngwaf-revproxy-9b976bd75-mzwdh -- /bin/sh

# helpful command when troubleshooting kubectl secrets
# https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/
# kubectl get secrets
# kubectl describe secret ngwaf-agent-keys
# kubectl get secret ngwaf-agent-keys -o jsonpath='{.data}' | jq .accesskeyid -r | base64 -D
# kubectl delete secret ngwaf-agent-keys

logs:
	kubectl logs `kubectl get pods | tail -n +2 | awk '{print $$1}'` -c nginx
