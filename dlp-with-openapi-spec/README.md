# OpenAPI Validation for Requests and Responses for JavaScript

An application template for validating requests and responses against an OpenAPI 3.x definition, in JavaScript, for Fastly's Compute@Edge environment.

## OpenAPI, briefly

The [OpenAPI Specification](https://spec.openapis.org/oas/latest.html) (OAS – originally based on the [Swagger Specification](https://swagger.io/specification/)) defines a standard, language-agnostic interface to RESTful APIs which allows both humans and computers to discover and understand the capabilities of the service without access to source code, additional documentation, or inspection of network traffic.

An OpenAPI definition is a document (or set of documents) that defines or describes an API.

## How does this help with Data Loss Prevention (DLP)?

Within an OpenAPI spec, you may define the schema and format for a response. This is helpful if you want to control what type of data is allowed to be returned in a response. A pattern may be defined within an OpenAPI spec using a (pattern)[https://json-schema.org/understanding-json-schema/reference/string.html#pattern].

✅ Reduce the likelihood that sensitive data may be returned back to users or attackers.
✅ Improved API security

## Usage

Before running this example, make sure your OpenAPI spec is dereferenced. I made another tool (json-dereference)[https://github.com/BrooksCunningham/json-dereference/tree/main] that can provide a dereferenced the OpenAPI spec.

Run `fastly compute serve` to try out this Compute@Edge app on your local machine, or `fastly compute publish` to publish a new Compute@Edge service.

When running this app locally try running commands like the following.

```
# Request validation success
curl -X POST http://127.0.0.1:7676/anything/login -H host:http.edgecompute.app -d '{"username":"foo", "password":"secretbar"}' -i
# Request validation fail because "username" is required fields in the request body
curl -X POST http://127.0.0.1:7676/anything/login -H host:http.edgecompute.app -d '{"foo":"abc"}' -i

# Request validation success
curl -X GET http://127.0.0.1:7676/html -i

# Response validation is successful
curl -X POST http://127.0.0.1:7676/anything/barfoo -H host:http.edgecompute.app -d '{"username":"foo", "password":"secretbar"}' -i
# Response validation fails because "foobar" is not allowed in the response body field "url".
curl -X POST http://127.0.0.1:7676/anything/foobar -H host:http.edgecompute.app -d '{"username":"foo", "password":"secretbar"}' -i
```
The response to the URL `/anything/foobar` will fail because the property "url" in the response schema does not allow the "foobar" in the response.

### Request handling

The default application behavior is to only forward valid requests to the origin, and return a synthetic HTTP 400 response for invalid requests.

OpenAPI validation errors are logged in both cases.

To forward all requests to the origin, set the constant `REJECT_INVALID_REQUESTS` to `false`.

**For more details about other starter kits for Compute@Edge, see the [Fastly Developer Hub](https://developer.fastly.com/solutions/starters)**

### Response handling


## Security issues

Please see our [SECURITY.md](https://github.com/fastly/compute-starter-kit-javascript-openapi-validation/blob/main/SECURITY.md) for guidance on reporting security-related issues.
