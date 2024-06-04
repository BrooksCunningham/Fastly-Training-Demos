clean:
	- pkill "fastly"
	- pkill "kubectl"
	- helm uninstall apiclarity -n apiclarity 
	- kubectl delete pvc -l app.kubernetes.io/instance=apiclarity -n apiclarity

build:
	make clean
	helm install --values apiclarity_values.yaml --create-namespace apiclarity apiclarity/apiclarity -n apiclarity
	@echo "Waiting for APIClarity to start up"; sleep 240
	kubectl port-forward -n apiclarity svc/apiclarity-apiclarity 8443:8443 &
	kubectl port-forward -n apiclarity svc/apiclarity-apiclarity 9000:9000 &
	fastly compute serve &

# Attempt to get the trace_source_token into a variable which may be used in the demo.
TRACE_SOURCE_TOKEN := $(shell curl --http1.1 --insecure -s -H 'Content-Type: application/json' -d '{"name":"apigee_gateway","type":"APIGEE_X"}' https://localhost:8443/api/control/traceSources|jq -r '.token')
demo:	
	@curl http://127.0.0.1:7676/get_sampled_logs -H 'content-type:application/json' -d '{ "ngwaf_email":"${NGWAF_EMAIL}", "ngwaf_token":"${NGWAF_TOKEN}", "corpName":"${NGWAF_CORP}", "siteName":"${NGWAF_SITE}", "TRACE_SOURCE_TOKEN":"${TRACE_SOURCE_TOKEN}" }'
	@printf "\n####\nNow go to https://127.0.0.1:8443 in your browser\n\n"

ui:
	kubectl port-forward -n apiclarity svc/apiclarity-apiclarity 8443:8443

trace:
	kubectl port-forward -n apiclarity svc/apiclarity-apiclarity 9000:9000

# debug:
# 	@echo "http http://127.0.0.1:7676/get_sampled_logs ngwaf_email=$$NGWAF_EMAIL ngwaf_token=$$NGWAF_TOKEN corpName=$$NGWAF_CORP siteName=$$NGWAF_SITE	TRACE_SOURCE_TOKE=${TRACE_SOURCE_TOKEN} -p=bBhH"

prep:
	@curl -ik -sD - -o /dev/null 'http://0.0.0.0:9999/v2/user/login?username=bob&password=sesime' 	-H 'accept: application/json'	-H 'host: petstore.swagger.io'   	
	@curl -ik -sD - -o /dev/null 'http://0.0.0.0:9999/v2/user/bob' 	-X 'OPTIONS' 	-H 'host: petstore.swagger.io' 	-H 'accept: */*' 		
	@curl -ik -sD - -o /dev/null 'http://0.0.0.0:9999/v2/user/bob' 	-X 'DELETE' 	-H 'accept: application/json'
	@curl -ik -sD - -o /dev/null 'http://0.0.0.0:9999/v2/user/bob' 	-X 'OPTIONS' 	-H 'accept: */*' 	-H 'host: petstore.swagger.io' 
	@curl -ik -sD - -o /dev/null 'http://0.0.0.0:9999/v2/user/bob' 	-X 'PUT' 	-H 'accept: application/json' 	-H 'cache-control: no-cache' 	-H 'content-type: application/json' 	-H 'origin: http://0.0.0.0:9999' --data-raw '{\n  "id": 0,\n  "username": "string",\n  "firstName": "string",\n  "lastName": "string",\n  "email": "string",\n  "password": "string",\n  "phone": "string",\n  "userStatus": 0\n}'
	@curl -ik -sD - -o /dev/null 'http://0.0.0.0:9999/v2/user/bob' 	-H 'accept: application/json' 
