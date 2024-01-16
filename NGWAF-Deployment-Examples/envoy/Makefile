
build:
	docker build -t envoy-sigsci .

run:
	docker run -it -p 9000:80 envoy-sigsci

admin:	
	docker run -it -p 9000:9901 envoy-sigsci

test:
	curl "127.0.0.1:9000/anything/123?i=../../../etc/passwd123" -i