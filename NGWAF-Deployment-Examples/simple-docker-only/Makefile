DOCKERNAME?=localfastlyngwaf

pull:
	docker pull signalsciences/sigsci-agent

run:
	@docker run --publish 8080:8888 --name $(DOCKERNAME) --env SIGSCI_ACCESSKEYID=${NGWAFACCESSKEYID} --env SIGSCI_SECRETACCESSKEY=${NGWAFACCESSKEYSECRET} --env SIGSCI_REVPROXY_LISTENER="app1:{listener=http://0.0.0.0:8888,upstreams=https://http-me.edgecompute.app:443/,pass-host-header=false}" -d signalsciences/sigsci-agent

runexec:
	@docker run --publish 8080:8888 --name $(DOCKERNAME) --env SIGSCI_ACCESSKEYID=${NGWAFACCESSKEYID} --env SIGSCI_SECRETACCESSKEY=${NGWAFACCESSKEYSECRET} --env SIGSCI_REVPROXY_LISTENER="app1:{listener=http://0.0.0.0:8888,upstreams=https://http-me.edgecompute.app:443/,pass-host-header=false}" -it signalsciences/sigsci-agent

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
