# Integrate sampled Fastly Next-Gen WAF logs with APIclarity
Extact data from the NGWAF logs and send that request and response data to locally running APIClarity to document you API.

https://docs.fastly.com/en/ngwaf/extract-your-data

https://github.com/openclarity/apiclarity

# Quickstart

## Build APIClarity and start a locally running Fastly Compute environment
`make build`

## Capture the APIClarity token and send a request to the Fastly Compute environment.
`make demo`
The request to Fastly Compute environment will do the following. 
* Query for a period of times worth of NGWAF Sampled logs
* Format that returned data for APIClarity
* Send the formatted dat to APIClarity

Capture the APIClarity Trace Source Token
```
TRACE_SOURCE_TOKEN=$(curl --http1.1 --insecure -s -H 'Content-Type: application/json' -d '{"name":"apigee_gateway","type":"APIGEE_X"}' https://localhost:8443/api/control/traceSources|jq -r '.token')
```

You may use `curl` or `http` to send the request to the locally running Fastly compute instance formatted like the following.

```
http http://127.0.0.1:7676/get_sampled_logs SIGSCI_EMAIL=$SIGSCI_EMAIL SIGSCI_TOKEN=$SIGSCI_TOKEN corpName=$TF_VAR_NGWAF_CORP siteName=$TF_VAR_NGWAF_SITE TRACE-SOURCE-TOKEN=$TRACE_SOURCE_TOKEN -p=b
```