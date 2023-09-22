#
```
docker pull signalsciences/sigsci-agent

docker run --name local-fastly-ngwaf \
--publish 8080:8888 \
--env SIGSCI_ACCESSKEYID="" \
--env SIGSCI_SECRETACCESSKEY="" \
--env SIGSCI_REVPROXY_LISTENER="app1:{listener=http://0.0.0.0:8888,upstreams=https://http-me.edgecompute.app:443/,pass-host-header=false}" \
-it signalsciences/sigsci-agent
```

From your local machine, run the command `curl http://0.0.0.0:8080` and see the agent registered in the UI.
