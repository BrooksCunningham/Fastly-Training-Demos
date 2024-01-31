DOCKERNAME?=localfastlyngwaf
# OPENAPISPECFILE?="https://http-me.edgecompute.app/static-assets/openapi-spec.json"
# OPENAPISPECFILE?="https://petstore.swagger.io/v2/swagger.json"
OPENAPISPECFILE?="http://host.docker.internal:9999/api/apiInventory/2/reconstructed_swagger.json"

pull:
	docker pull signalsciences/sigsci-agent

run:
	@docker run --publish 8080:8888 --name $(DOCKERNAME) --env SIGSCI_ACCESSKEYID=${NGWAFACCESSKEYID} --env SIGSCI_SECRETACCESSKEY=${NGWAFACCESSKEYSECRET} --env SIGSCI_REVPROXY_LISTENER="app1:{listener=http://0.0.0.0:8888,upstreams=https://http-me.edgecompute.app:443/,pass-host-header=false}" -d signalsciences/sigsci-agent

runexec:
	@docker run --publish 8888:8888 --publish 9999:9999 --name $(DOCKERNAME) --env SIGSCI_ACCESSKEYID=${NGWAFACCESSKEYID} --env SIGSCI_SECRETACCESSKEY=${NGWAFACCESSKEYSECRET} --env SIGSCI_WAF_DATA_LOG="/dev/stdout" --env SIGSCI_REVPROXY_LISTENER="app1:{listener=http://0.0.0.0:8888,upstreams=https://http-me.edgecompute.app:443/,pass-host-header=false}; app2:{listener=http://0.0.0.0:9999, upstreams=https://http-me.glitch.me/,pass-host-header=false}" -it signalsciences/sigsci-agent

runexecapi:
	@docker run --publish 8888:8888 --publish 9999:9999 --name $(DOCKERNAME) --env SIGSCI_ACCESSKEYID=${NGWAFACCESSKEYID} --env SIGSCI_SECRETACCESSKEY=${NGWAFACCESSKEYSECRET} --env SIGSCI_OPEN_API_SPEC_FILE=$(OPENAPISPECFILE) --env SIGSCI_WAF_DATA_LOG="/dev/stdout" --env SIGSCI_REVPROXY_LISTENER="app1:{listener=http://0.0.0.0:8888,upstreams=https://http-me.edgecompute.app:443/,pass-host-header=false}; petstore:{listener=http://0.0.0.0:9999, upstreams=https://petstore.swagger.io/,pass-host-header=false}" -it signalsciences/sigsci-agent

apidemo:
	@echo "curl -H 'host:petstore.swagger.io' http://0.0.0.0:9999/user/bob"
	@echo "curl -H 'host:petstore.swagger.io' http://0.0.0.0:9999/v2/user/bob"

exec:
	docker exec -it $(DOCKERNAME) /bin/sh

clean:
	-docker kill $(DOCKERNAME)
	-docker rm $(DOCKERNAME)

rerun:
	make clean
	make run

rerunexec:
	make clean
	make runexec

rerunexecapi:
	make clean
	make runexecapi
