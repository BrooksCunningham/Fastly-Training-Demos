KUBEDEPLOYMENT?=dotnet-module-with-ngwaf-sidecar
KUBEYAML?=dotnet_sidecar.yaml
DOCKERIMAGE?=dotnet-ngwaf-module

# Environment variables $NGWAFACCESSKEYID and $NGWAFACCESSKEYSECRET must already be set before running `make build`
build:
	- docker build . -t mylocaltrainingimages/$(DOCKERIMAGE)
	- docker run --name $(DOCKERIMAGE) -d -i -t mylocaltrainingimages/$(DOCKERIMAGE)
	
clean:
	- docker kill $(DOCKERIMAGE)
	- docker rm $(DOCKERIMAGE)

rebuild:
	make clean
	make build

exec:
	docker exec -it $(DOCKERIMAGE) /bin/sh
