clean:
	- pkill "fastly"
	- pkill "kubectl"
	- helm uninstall apiclarity -n apiclarity 
	- kubectl delete pvc -l app.kubernetes.io/instance=apiclarity -n apiclarity

apiclaritybuild:
	make clean
	helm install --values apiclarity_values.yaml --create-namespace apiclarity apiclarity/apiclarity -n apiclarity
	@echo "Waiting for APIClarity to start up"; sleep 240
	kubectl port-forward -n apiclarity svc/apiclarity-apiclarity 8443:8443 &
	kubectl port-forward -n apiclarity svc/apiclarity-apiclarity 9000:9000 &
	kubectl port-forward -n apiclarity svc/apiclarity-apiclarity 8080:8080 &

# fastly compute serve &

# Attempt to get the trace_source_token into a variable which may be used in the demo.
TRACE_SOURCE_TOKEN := $(shell curl --http1.1 --insecure -s -H 'Content-Type: application/json' -d '{"name":"apigee_gateway","type":"APIGEE_X"}' https://localhost:8443/api/control/traceSources|jq -r '.token')


demo:
	@curl -ik -sD - -o /dev/null 'http://0.0.0.0:7676/anything/v2/user/login?username=bob&password=sesime' -H 'host:http-me.edgecompute.app' -H 'accept: application/json'   	
	@curl -ik -sD - -o /dev/null 'http://0.0.0.0:7676/anything/v2/user/bob' -X 'OPTIONS' 	-H 'host:http-me.edgecompute.app' 	-H 'accept: */*' 		
	@curl -ik -sD - -o /dev/null 'http://0.0.0.0:7676/anything/v2/user/bob' -X 'DELETE' -H 'host:http-me.edgecompute.app' -H 'accept: application/json'
	@curl -ik -sD - -o /dev/null 'http://0.0.0.0:7676/anything/v2/user/bob' -X 'OPTIONS' -H 'host:http-me.edgecompute.app' -H 'accept: */*'
	@curl -ik -sD - -o /dev/null 'http://0.0.0.0:7676/anything/v2/user/bob' -X 'PUT' -H 'host:http-me.edgecompute.app' -H 'accept: application/json' -H 'cache-control: no-cache' 	-H 'content-type: application/json' 	-H 'origin: http://0.0.0.0:9999' --data-raw '{\n  "id": 0,\n  "username": "string",\n  "firstName": "string",\n  "lastName": "string",\n  "email": "string",\n  "password": "string",\n  "phone": "string",\n  "userStatus": 0\n}'
	@curl -ik -sD - -o /dev/null 'http://0.0.0.0:7676/anything/v2/user/bob' -H 'host:http-me.edgecompute.app' -H 'accept: application/json' 
