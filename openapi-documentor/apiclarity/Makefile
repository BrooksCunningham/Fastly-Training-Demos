build:
	helm install --values values.yaml --create-namespace apiclarity apiclarity/apiclarity -n apiclarity

ui:
	kubectl port-forward -n apiclarity svc/apiclarity-apiclarity 8443:8443

trace:
	kubectl port-forward -n apiclarity svc/apiclarity-apiclarity 9000:9000

token:
	curl --http1.1 --insecure -s -H 'Content-Type: application/json' -d '{"name":"apigee_gateway","type":"APIGEE_X"}' https://localhost:8443/api/control/traceSources|jq -r '.token'

clean:
	- helm uninstall apiclarity -n apiclarity 
	- kubectl delete pvc -l app.kubernetes.io/instance=apiclarity -n apiclarity


