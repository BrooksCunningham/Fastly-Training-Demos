# Generate an OpenAPI spec using Fastly and APIClarity

# Here's the steps to generate a spec file

## Start up an APIClarity environment

Run `make buildapiclarity`
In 2 different terminals run `make trace` and `make ui`

Set the TRACE_SOURCE_TOKEN token.
`export TRACE_SOURCE_TOKEN=$(curl --http1.1 --insecure -s -H 'Content-Type: application/json' -d '{"name":"apigee_gateway","type":"APIGEE_X"}' http://localhost:8080/api/control/traceSources | jq -r '.token')`

## Generate some traffic to the local Fastly service

```
curl -H host:http-me.edgecompute.app http://127.0.0.1:7676/status/200
curl -H host:http-me.edgecompute.app http://127.0.0.1:7676/status/302
curl -H host:http-me.edgecompute.app http://127.0.0.1:7676/status/404
curl -H host:http-me.edgecompute.app http://127.0.0.1:7676/status/504
```

This Fastly service will then format the request and response data before sending the traffic to the local APIClarity environment listening on port 9000.

httpie is nice too :-)
```
http http://127.0.0.1:7676/anything/555 host:http-me.edgecompute.app foo=bar
```

Check out the APIClarity UI for the API Spec details.
