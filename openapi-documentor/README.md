# Send network data to stdout which may be used to build an openapi spec file

# Here's the steps to generate a spec file

## Start up an APIClarity environment

See `./apiclarity/values.yaml` for those instructions

## Update the fastly environment

Create or update the `./apiclarity_configstore.json` file with the APIClarity key for your install.

```
{
    "trace_source_token": "YOUR_KEY_HERE"
}
```

Start up a local fastly compute instance
```
fastly compute serve
```

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
