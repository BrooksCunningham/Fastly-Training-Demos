DOCKERNAME?=haproxy

kbuild:
	kubectl apply -f haproxy.yaml

kdelete:
	kubectl delete -f haproxy.yaml

run:
	docker run --name $(DOCKERNAME) -d mylocaltrainingimages/haproxy-ngwaf-module

runexec:
	docker run --name $(DOCKERNAME) -it mylocaltrainingimages/haproxy-ngwaf-module

exec:
	docker exec -it $(DOCKERNAME) /bin/sh

ddelete:
	- docker kill $(DOCKERNAME)
	- docker rm $(DOCKERNAME)

krebuild:
	make destroy
	sleep 5
	make build
	