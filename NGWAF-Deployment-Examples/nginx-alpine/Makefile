DOCKERUSER?=sigsci
DOCKERNAME?=sigsci-nginx-alpine
DOCKERTAG?=latest
SIGSCI_HOSTNAME?=nginx-alpine
EXPOSE_PORT?=4000
AGENT_CONF?=$(shell pwd)/agent.conf

build:
	docker build -t $(DOCKERUSER)/$(DOCKERNAME):$(DOCKERTAG) .

build-no-cache:
	docker build --no-cache -t $(DOCKERUSER)/$(DOCKERNAME):$(DOCKERTAG) .

run:
# docker run --name $(DOCKERNAME) --hostname $(SIGSCI_HOSTNAME) -p $(EXPOSE_PORT):80 -d $(DOCKERUSER)/$(DOCKERNAME)
	docker run -v $(AGENT_CONF):/etc/sigsci/agent.conf --name $(DOCKERNAME) --hostname $(SIGSCI_HOSTNAME) -p $(EXPOSE_PORT):80 -d $(DOCKERUSER)/$(DOCKERNAME)

runexec:
	docker run -v $(AGENT_CONF):/etc/sigsci/agent.conf -p $(EXPOSE_PORT):80 --name $(DOCKERNAME) --hostname $(SIGSCI_HOSTNAME) -it $(DOCKERUSER)/$(DOCKERNAME)

rerunexec:
	make clean
	make build
	make runexec

deploy:
	docker push $(DOCKERUSER)/$(DOCKERNAME):$(DOCKERTAG)
	
clean:
	-docker kill $(DOCKERNAME)
	-docker rm $(DOCKERNAME)

destroy:
	-docker kill $(DOCKERNAME)
	-docker rm $(DOCKERNAME)
	-docker rmi $(DOCKERUSER)/$(DOCKERNAME):$(DOCKERTAG)