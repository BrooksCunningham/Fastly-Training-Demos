// / <reference types="@fastly/js-compute" />

import { env } from "fastly:env";
import { includeBytes } from "fastly:experimental";
import { OpenAPIValidator } from "openapi-backend";

const textDecoder = new TextDecoder();

// A valid and fully-dereferenced OpenAPI 3.x definition.
const openAPIDefinition = JSON.parse(textDecoder.decode(includeBytes('src/definition.json')));


// If true, invalid requests will be rejected with a 400 response.
// Otherwise, they will be forwarded to the origin after OpenAPI validation errors are logged.
const REJECT_INVALID_REQUESTS = false;
const REJECT_INVALID_RESPONSE = true;
// The origin server that requests are proxied onto.
const BACKEND = "origin";

addEventListener("fetch", (event) => event.respondWith(handleRequest(event)));

// Validates all requests against an OpenAPI definition.
async function handleRequest(event) {
  // Log service version
  console.log("FASTLY_SERVICE_VERSION:", env('FASTLY_SERVICE_VERSION') || 'local');
  
  // Initialize an OpenAPI validator using the OpenAPI definition.
  // https://github.com/anttiviljami/openapi-backend/blob/master/DOCS.md#new-openapivalidatoropts
  const openAPIValidator = new OpenAPIValidator({
    definition: openAPIDefinition,
    lazyCompileValidators: true,
  });

  const req = event.request;

  // clone the request to use for validation.
  const validationReq = validationReqFunc(req);

  // Validate the request.
  const reqValidationResult = await validateRequest(validationReq, openAPIValidator);
  
  console.log(`request validation: `, reqValidationResult);

  // Forward request to the origin
  let backendResp = await fetch(req, { backend: BACKEND });

  // clone the response to use for validation
  let responseValidationResult = {};
  [backendResp, responseValidationResult] = await validateResponse(backendResp, openAPIValidator, reqValidationResult.operationId);
  console.log(`Response Validation Result: `, responseValidationResult);

  // if there is an error, then return the error
  if (responseValidationResult.isValid === false 
    && REJECT_INVALID_RESPONSE === true
    && responseValidationResult.error !== "None"){
    return new Response(responseValidationResult.error, {
      status: 400
      })
  }

  // Return the original backend response back to the client.
  return backendResp
}

async function validateRequest(req, openAPIValidator){
  
  try {
    const url = new URL(req.url);
    // Build a normalized Request object to pass to the OpenAPI validator.
    // https://github.com/anttiviljami/openapi-backend/blob/master/DOCS.md#request-object
    let normalizedForValidation = {};
    if (["GET", "HEAD"].includes(req.method)) {
      normalizedForValidation = {
        method: req.method,
        // path of the request
        path: url.pathname,
        // HTTP request headers
        headers: Object.fromEntries(req.headers.entries()),
        // parsed query parameters
        query: Object.fromEntries(url.searchParams.entries()),
        // the request body is not available for a GET request
        // body: reqBodyText,
      };
    }
    
    if (req.method == "POST") {
      const reqBodyText = await req.text();
      normalizedForValidation = {
        method: req.method,
        // path of the request
        path: url.pathname,
        // HTTP request headers
        headers: Object.fromEntries(req.headers.entries()),
        // parsed query parameters
        query: Object.fromEntries(url.searchParams.entries()),
        // the request body is not available for a GET request
        body: reqBodyText,
      };
    }

    // Match the request to an operation from the OpenAPI definition.
    const operation = openAPIValidator.router.matchOperation(
      normalizedForValidation
    );

    // Validate the request against the matched operation (if found).
    const reqValidationResult = openAPIValidator.validateRequest(
      normalizedForValidation,
      operation
    );
    // Handle request validation errors.
    if (!reqValidationResult.valid) {
      console.error(
        "OpenAPI request validation errors",
        reqValidationResult.errors
      );
      throw new Error("Invalid request");
    }
  
    return {isValid: true, "operationId" : operation.operationId}
  
  } catch (error) {
    // Handle errors, including when an operation is not matched.
    console.error("OpenAPI request validation failed", error);
    if (REJECT_INVALID_REQUESTS) {
      // Send a synthetic 400 response.
      // return new Response("Bad Request because of request validation", { status: 400 });
      return error
    }
    return {"isValid": false, "operationId" : "nil"}
  }
}

async function validateResponse(response, openAPIValidator, operationId){
  // Take care! .text() will consume the entire body into memory!
  let respBodyText = await response.text();
  let newResp = new Response(respBodyText);

  // Only evaluate requests that are formated as JSON from the origin for this example
  if (response.headers.get("content-type").includes("json")) {
    try {    
      // Only do the response body check if the response body is valid JSON.
      console.log(`operation.operationId:`, operationId);
      const validateResponse = openAPIValidator.validateResponse(JSON.parse(respBodyText), operationId);
    
      if (validateResponse.errors) {
        // there were errors, then throw an error
        console.log(validateResponse.errors);
        throw new Error("Invalid RESPONSE");
      }
      console.log(`Inspected response: TRUE`);
      
      return [newResp, {"isValid": true, "error" : "None"}]
    } catch (error) {
      // Handle errors, including when an operation is not matched.
      console.error("OpenAPI RESPONSE validation failed", error);
      // return the original response and status on the response validation
      return [newResp, {"isValid": false, "error" : error}]
    }
  }
  // return when there is no response inspected
  return [newResp, {"isValid": false, "error" : "None"}]
}

const validationReqFunc = (req) => {
  // Cannot use the clone function if the request is a GET or HEAD
  if (["GET", "HEAD"].includes(req.method)){
    return new Request(req, {
      method: req.method,
      headers: req.headers,
    })
  }
  return req.clone();
}

// const cloneRespFunc = (resp) => {
//   return new Response(resp)
// }

/*
const dereferencedOpenAPIDefinition = {
  "openapi": "3.0.1",
  "info": {
    "title": "httpbin.org",
    "description": "A simple HTTP Request & Response Service.",
    "version": "0.9.2"
  },
  "servers": [
    {
      "url": "https://httpbin.org/"
    }
  ],
  "tags": [
    {
      "name": "HTTP Methods",
      "description": "Testing different HTTP verbs"
    },
    {
      "name": "Auth",
      "description": "Auth methods"
    },
    {
      "name": "Status codes",
      "description": "Generates responses with given status code"
    },
    {
      "name": "Request inspection",
      "description": "Inspect the request data"
    },
    {
      "name": "Response inspection",
      "description": "Inspect the response data like caching and headers"
    },
    {
      "name": "Response formats",
      "description": "Returns responses in different data formats"
    },
    {
      "name": "Dynamic data",
      "description": "Generates random and dynamic data"
    },
    {
      "name": "Cookies",
      "description": "Creates, reads and deletes Cookies"
    },
    {
      "name": "Images",
      "description": "Returns different image formats"
    },
    {
      "name": "Redirects",
      "description": "Returns different redirect responses"
    },
    {
      "name": "Anything",
      "description": "Returns anything that is passed to request"
    }
  ],
  "paths": {
    "/absolute-redirect/{n}": {
      "get": {
        "tags": [
          "Redirects"
        ],
        "summary": "Absolutely 302 Redirects n times.",
        "parameters": [
          {
            "name": "n",
            "in": "path",
            "required": true,
            "schema": {
              "type": "integer"
            }
          }
        ],
        "responses": {
          "302": {
            "description": "A redirection.",
            "content": {}
          }
        },
        "operationId": "getabsoluteredirect{n}"
      }
    },
    "/anything": {
      "get": {
        "tags": [
          "Anything"
        ],
        "summary": "Returns anything passed in request data.",
        "responses": {
          "200": {
            "description": "Anything passed in request",
            "content": {}
          }
        },
        "operationId": "getanything"
      },
      "put": {
        "tags": [
          "Anything"
        ],
        "summary": "Returns anything passed in request data.",
        "responses": {
          "200": {
            "description": "Anything passed in request",
            "content": {}
          }
        },
        "operationId": "putanything"
      },
      "post": {
        "tags": [
          "Anything"
        ],
        "summary": "Returns anything passed in request data.",
        "responses": {
          "200": {
            "description": "Anything passed in request",
            "content": {}
          }
        },
        "operationId": "postanything"
      },
      "delete": {
        "tags": [
          "Anything"
        ],
        "summary": "Returns anything passed in request data.",
        "responses": {
          "200": {
            "description": "Anything passed in request",
            "content": {}
          }
        },
        "operationId": "deleteanything"
      },
      "patch": {
        "tags": [
          "Anything"
        ],
        "summary": "Returns anything passed in request data.",
        "responses": {
          "200": {
            "description": "Anything passed in request",
            "content": {}
          }
        },
        "operationId": "patchanything"
      }
    },
    "/anything/{anything}": {
      "get": {
        "tags": [
          "Anything"
        ],
        "summary": "Returns anything passed in request data.",
        "parameters": [
          {
            "name": "anything",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Anything passed in request",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "required": [
                    "url"
                  ],
                  "properties": {
                    "url": {
                      "type": "string",
                      "example": "https://localhost/anything/200",
                      "pattern": "^((?!foobar).)*$"
                    }
                  }
                }
              }
            }
          }
        },
        "operationId": "getanything{anything}"
      },
      "put": {
        "tags": [
          "Anything"
        ],
        "summary": "Returns anything passed in request data.",
        "parameters": [
          {
            "name": "anything",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Anything passed in request",
            "content": {}
          }
        },
        "operationId": "putanything{anything}"
      },
      "post": {
        "tags": [
          "Anything"
        ],
        "summary": "Returns anything passed in request data.",
        "parameters": [
          {
            "name": "anything",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Anything passed in request",
            "content": {}
          }
        },
        "operationId": "postanything{anything}"
      },
      "delete": {
        "tags": [
          "Anything"
        ],
        "summary": "Returns anything passed in request data.",
        "parameters": [
          {
            "name": "anything",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Anything passed in request",
            "content": {}
          }
        },
        "operationId": "deleteanything{anything}"
      },
      "patch": {
        "tags": [
          "Anything"
        ],
        "summary": "Returns anything passed in request data.",
        "parameters": [
          {
            "name": "anything",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Anything passed in request",
            "content": {}
          }
        },
        "operationId": "patchanything{anything}"
      }
    },
    "/base64/{value}": {
      "get": {
        "tags": [
          "Dynamic data"
        ],
        "summary": "Decodes base64url-encoded string.",
        "parameters": [
          {
            "name": "value",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string",
              "default": "SFRUUEJJTiBpcyBhd2Vzb21l"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Decoded base64 content.",
            "content": {}
          }
        },
        "operationId": "getbase64{value}"
      }
    },
    "/basic-auth/{user}/{passwd}": {
      "get": {
        "tags": [
          "Auth"
        ],
        "summary": "Prompts the user for authorization using HTTP Basic Auth.",
        "parameters": [
          {
            "name": "user",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "passwd",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Sucessful authentication.",
            "content": {}
          },
          "401": {
            "description": "Unsuccessful authentication.",
            "content": {}
          }
        },
        "operationId": "getbasicauth{user}{passwd}"
      }
    },
    "/bearer": {
      "get": {
        "tags": [
          "Auth"
        ],
        "summary": "Prompts the user for authorization using bearer authentication.",
        "parameters": [
          {
            "name": "Authorization",
            "in": "header",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Sucessful authentication.",
            "content": {}
          },
          "401": {
            "description": "Unsuccessful authentication.",
            "content": {}
          }
        },
        "operationId": "getbearer"
      }
    },
    "/brotli": {
      "get": {
        "tags": [
          "Response formats"
        ],
        "summary": "Returns Brotli-encoded data.",
        "responses": {
          "200": {
            "description": "Brotli-encoded data.",
            "content": {}
          }
        },
        "operationId": "getbrotli"
      }
    },
    "/bytes/{n}": {
      "get": {
        "tags": [
          "Dynamic data"
        ],
        "summary": "Returns n random bytes generated with given seed",
        "parameters": [
          {
            "name": "n",
            "in": "path",
            "required": true,
            "schema": {
              "type": "integer"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Bytes.",
            "content": {}
          }
        },
        "operationId": "getbytes{n}"
      }
    },
    "/cache": {
      "get": {
        "tags": [
          "Response inspection"
        ],
        "summary": "Returns a 304 if an If-Modified-Since header or If-None-Match is present. Returns the same as a GET otherwise.",
        "parameters": [
          {
            "name": "If-Modified-Since",
            "in": "header",
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "If-None-Match",
            "in": "header",
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Cached response",
            "content": {}
          },
          "304": {
            "description": "Modified",
            "content": {}
          }
        },
        "operationId": "getcache"
      }
    },
    "/cache/{value}": {
      "get": {
        "tags": [
          "Response inspection"
        ],
        "summary": "Sets a Cache-Control header for n seconds.",
        "parameters": [
          {
            "name": "value",
            "in": "path",
            "required": true,
            "schema": {
              "type": "integer"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Cache control set",
            "content": {}
          }
        },
        "operationId": "getcache{value}"
      }
    },
    "/cookies": {
      "get": {
        "tags": [
          "Cookies"
        ],
        "summary": "Returns cookie data.",
        "responses": {
          "200": {
            "description": "Set cookies.",
            "content": {}
          }
        },
        "operationId": "getcookies"
      }
    },
    "/cookies/delete": {
      "get": {
        "tags": [
          "Cookies"
        ],
        "summary": "Deletes cookie(s) as provided by the query string and redirects to cookie list.",
        "parameters": [
          {
            "name": "freeform",
            "in": "query",
            "allowEmptyValue": true,
            "style": "form",
            "explode": true,
            "schema": {
              "type": "array",
              "items": {
                "type": "string"
              }
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Redirect to cookie list",
            "content": {}
          }
        },
        "operationId": "getcookiesdelete"
      }
    },
    "/cookies/set": {
      "get": {
        "tags": [
          "Cookies"
        ],
        "summary": "Sets cookie(s) as provided by the query string and redirects to cookie list.",
        "parameters": [
          {
            "name": "freeform",
            "in": "query",
            "allowEmptyValue": true,
            "style": "form",
            "explode": true,
            "schema": {
              "type": "array",
              "items": {
                "type": "string"
              }
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Redirect to cookie list",
            "content": {}
          }
        },
        "operationId": "getcookiesset"
      }
    },
    "/cookies/set/{name}/{value}": {
      "get": {
        "tags": [
          "Cookies"
        ],
        "summary": "Sets a cookie and redirects to cookie list.",
        "parameters": [
          {
            "name": "name",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "value",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Set cookies and redirects to cookie list.",
            "content": {}
          }
        },
        "operationId": "getcookiesset{name}{value}"
      }
    },
    "/deflate": {
      "get": {
        "tags": [
          "Response formats"
        ],
        "summary": "Returns Deflate-encoded data.",
        "responses": {
          "200": {
            "description": "Defalte-encoded data.",
            "content": {}
          }
        },
        "operationId": "getdeflate"
      }
    },
    "/delay/{delay}": {
      "get": {
        "tags": [
          "Dynamic data"
        ],
        "summary": "Returns a delayed response (max of 10 seconds).",
        "parameters": [
          {
            "name": "delay",
            "in": "path",
            "required": true,
            "schema": {
              "type": "integer"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "A delayed response.",
            "content": {}
          }
        },
        "operationId": "getdelay{delay}"
      },
      "put": {
        "tags": [
          "Dynamic data"
        ],
        "summary": "Returns a delayed response (max of 10 seconds).",
        "parameters": [
          {
            "name": "delay",
            "in": "path",
            "required": true,
            "schema": {
              "type": "integer"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "A delayed response.",
            "content": {}
          }
        },
        "operationId": "putdelay{delay}"
      },
      "post": {
        "tags": [
          "Dynamic data"
        ],
        "summary": "Returns a delayed response (max of 10 seconds).",
        "parameters": [
          {
            "name": "delay",
            "in": "path",
            "required": true,
            "schema": {
              "type": "integer"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "A delayed response.",
            "content": {}
          }
        },
        "operationId": "postdelay{delay}"
      },
      "delete": {
        "tags": [
          "Dynamic data"
        ],
        "summary": "Returns a delayed response (max of 10 seconds).",
        "parameters": [
          {
            "name": "delay",
            "in": "path",
            "required": true,
            "schema": {
              "type": "integer"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "A delayed response.",
            "content": {}
          }
        },
        "operationId": "deletedelay{delay}"
      },
      "patch": {
        "tags": [
          "Dynamic data"
        ],
        "summary": "Returns a delayed response (max of 10 seconds).",
        "parameters": [
          {
            "name": "delay",
            "in": "path",
            "required": true,
            "schema": {
              "type": "integer"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "A delayed response.",
            "content": {}
          }
        },
        "operationId": "patchdelay{delay}"
      }
    },
    "/delete": {
      "delete": {
        "tags": [
          "HTTP Methods"
        ],
        "summary": "The request's DELETE parameters.",
        "responses": {
          "200": {
            "description": "The request's DELETE parameters.",
            "content": {}
          }
        },
        "operationId": "deletedelete"
      }
    },
    "/deny": {
      "get": {
        "tags": [
          "Response formats"
        ],
        "summary": "Returns page denied by robots.txt rules.",
        "responses": {
          "200": {
            "description": "Denied message",
            "content": {}
          }
        },
        "operationId": "getdeny"
      }
    },
    "/digest-auth/{qop}/{user}/{passwd}": {
      "get": {
        "tags": [
          "Auth"
        ],
        "summary": "Prompts the user for authorization using Digest Auth.",
        "parameters": [
          {
            "name": "qop",
            "in": "path",
            "description": "auth or auth-int",
            "required": true,
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "user",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "passwd",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Sucessful authentication.",
            "content": {}
          },
          "401": {
            "description": "Unsuccessful authentication.",
            "content": {}
          }
        },
        "operationId": "getdigestauth{qop}{user}{passwd}"
      }
    },
    "/digest-auth/{qop}/{user}/{passwd}/{algorithm}": {
      "get": {
        "tags": [
          "Auth"
        ],
        "summary": "Prompts the user for authorization using Digest Auth + Algorithm.",
        "parameters": [
          {
            "name": "qop",
            "in": "path",
            "description": "auth or auth-int",
            "required": true,
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "user",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "passwd",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "algorithm",
            "in": "path",
            "description": "MD5, SHA-256, SHA-512",
            "required": true,
            "schema": {
              "type": "string",
              "default": "MD5"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Sucessful authentication.",
            "content": {}
          },
          "401": {
            "description": "Unsuccessful authentication.",
            "content": {}
          }
        },
        "operationId": "getdigestauth{qop}{user}{passwd}{algorithm}"
      }
    },
    "/digest-auth/{qop}/{user}/{passwd}/{algorithm}/{stale_after}": {
      "get": {
        "tags": [
          "Auth"
        ],
        "summary": "Prompts the user for authorization using Digest Auth + Algorithm.",
        "description": "allow settings the stale_after argument.\n",
        "parameters": [
          {
            "name": "qop",
            "in": "path",
            "description": "auth or auth-int",
            "required": true,
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "user",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "passwd",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "algorithm",
            "in": "path",
            "description": "MD5, SHA-256, SHA-512",
            "required": true,
            "schema": {
              "type": "string",
              "default": "MD5"
            }
          },
          {
            "name": "stale_after",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string",
              "default": "never"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Sucessful authentication.",
            "content": {}
          },
          "401": {
            "description": "Unsuccessful authentication.",
            "content": {}
          }
        },
        "operationId": "getdigestauth{qop}{user}{passwd}{algorithm}{stale_after}"
      }
    },
    "/drip": {
      "get": {
        "tags": [
          "Dynamic data"
        ],
        "summary": "Drips data over a duration after an optional initial delay.",
        "parameters": [
          {
            "name": "duration",
            "in": "query",
            "description": "The amount of time (in seconds) over which to drip each byte",
            "schema": {
              "type": "number",
              "default": 2
            }
          },
          {
            "name": "numbytes",
            "in": "query",
            "description": "The number of bytes to respond with",
            "schema": {
              "type": "integer",
              "default": 10
            }
          },
          {
            "name": "code",
            "in": "query",
            "description": "The response code that will be returned",
            "schema": {
              "type": "integer",
              "default": 200
            }
          },
          {
            "name": "delay",
            "in": "query",
            "description": "The amount of time (in seconds) to delay before responding",
            "schema": {
              "type": "number",
              "default": 2
            }
          }
        ],
        "responses": {
          "200": {
            "description": "A dripped response.",
            "content": {}
          }
        },
        "operationId": "getdrip"
      }
    },
    "/encoding/utf8": {
      "get": {
        "tags": [
          "Response formats"
        ],
        "summary": "Returns a UTF-8 encoded body.",
        "responses": {
          "200": {
            "description": "Encoded UTF-8 content.",
            "content": {}
          }
        },
        "operationId": "getencodingutf8"
      }
    },
    "/etag/{etag}": {
      "get": {
        "tags": [
          "Response inspection"
        ],
        "summary": "Assumes the resource has the given etag and responds to If-None-Match and If-Match headers appropriately.",
        "parameters": [
          {
            "name": "If-None-Match",
            "in": "header",
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "If-Match",
            "in": "header",
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "etag",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Normal response",
            "content": {}
          },
          "412": {
            "description": "match",
            "content": {}
          }
        },
        "operationId": "getetag{etag}"
      }
    },
    "/get": {
      "get": {
        "tags": [
          "HTTP Methods"
        ],
        "summary": "The request's query parameters.",
        "responses": {
          "200": {
            "description": "The request's query parameters.",
            "content": {}
          }
        },
        "operationId": "getget"
      }
    },
    "/gzip": {
      "get": {
        "tags": [
          "Response formats"
        ],
        "summary": "Returns GZip-encoded data.",
        "responses": {
          "200": {
            "description": "GZip-encoded data.",
            "content": {}
          }
        },
        "operationId": "getgzip"
      }
    },
    "/headers": {
      "get": {
        "tags": [
          "Request inspection"
        ],
        "summary": "Return the incoming request's HTTP headers.",
        "responses": {
          "200": {
            "description": "The request's headers.",
            "content": {}
          }
        },
        "operationId": "getheaders"
      }
    },
    "/hidden-basic-auth/{user}/{passwd}": {
      "get": {
        "tags": [
          "Auth"
        ],
        "summary": "Prompts the user for authorization using HTTP Basic Auth.",
        "parameters": [
          {
            "name": "user",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "passwd",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Sucessful authentication.",
            "content": {}
          },
          "404": {
            "description": "Unsuccessful authentication.",
            "content": {}
          }
        },
        "operationId": "gethiddenbasicauth{user}{passwd}"
      }
    },
    "/html": {
      "get": {
        "tags": [
          "Response formats"
        ],
        "summary": "Returns a simple HTML document.",
        "responses": {
          "200": {
            "description": "An HTML page.",
            "content": {}
          }
        },
        "operationId": "gethtml"
      }
    },
    "/image": {
      "get": {
        "tags": [
          "Images"
        ],
        "summary": "Returns a simple image of the type suggest by the Accept header.",
        "responses": {
          "200": {
            "description": "An image.",
            "content": {}
          }
        },
        "operationId": "getimage"
      }
    },
    "/image/jpeg": {
      "get": {
        "tags": [
          "Images"
        ],
        "summary": "Returns a simple JPEG image.",
        "responses": {
          "200": {
            "description": "A JPEG image.",
            "content": {}
          }
        },
        "operationId": "getimagejpeg"
      }
    },
    "/image/png": {
      "get": {
        "tags": [
          "Images"
        ],
        "summary": "Returns a simple PNG image.",
        "responses": {
          "200": {
            "description": "A PNG image.",
            "content": {}
          }
        },
        "operationId": "getimagepng"
      }
    },
    "/image/svg": {
      "get": {
        "tags": [
          "Images"
        ],
        "summary": "Returns a simple SVG image.",
        "responses": {
          "200": {
            "description": "An SVG image.",
            "content": {}
          }
        },
        "operationId": "getimagesvg"
      }
    },
    "/image/webp": {
      "get": {
        "tags": [
          "Images"
        ],
        "summary": "Returns a simple WEBP image.",
        "responses": {
          "200": {
            "description": "A WEBP image.",
            "content": {}
          }
        },
        "operationId": "getimagewebp"
      }
    },
    "/ip": {
      "get": {
        "tags": [
          "Request inspection"
        ],
        "summary": "Returns the requester's IP Address.",
        "responses": {
          "200": {
            "description": "The Requester's IP Address.",
            "content": {}
          }
        },
        "operationId": "getip"
      }
    },
    "/json": {
      "get": {
        "tags": [
          "Response formats"
        ],
        "summary": "Returns a simple JSON document.",
        "responses": {
          "200": {
            "description": "An JSON document.",
            "content": {}
          }
        },
        "operationId": "getjson"
      }
    },
    "/links/{n}/{offset}": {
      "get": {
        "tags": [
          "Dynamic data"
        ],
        "summary": "Generate a page containing n links to other pages which do the same.",
        "parameters": [
          {
            "name": "n",
            "in": "path",
            "required": true,
            "schema": {
              "type": "integer"
            }
          },
          {
            "name": "offset",
            "in": "path",
            "required": true,
            "schema": {
              "type": "integer"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "HTML links.",
            "content": {}
          }
        },
        "operationId": "getlinks{n}{offset}"
      }
    },
    "/patch": {
      "patch": {
        "tags": [
          "HTTP Methods"
        ],
        "summary": "The request's PATCH parameters.",
        "responses": {
          "200": {
            "description": "The request's PATCH parameters.",
            "content": {}
          }
        },
        "operationId": "patchpatch"
      }
    },
    "/post": {
      "post": {
        "tags": [
          "HTTP Methods"
        ],
        "summary": "The request's POST parameters.",
        "responses": {
          "200": {
            "description": "The request's POST parameters.",
            "content": {}
          }
        },
        "operationId": "postpost"
      }
    },
    "/put": {
      "put": {
        "tags": [
          "HTTP Methods"
        ],
        "summary": "The request's PUT parameters.",
        "responses": {
          "200": {
            "description": "The request's PUT parameters.",
            "content": {}
          }
        },
        "operationId": "putput"
      }
    },
    "/range/{numbytes}": {
      "get": {
        "tags": [
          "Dynamic data"
        ],
        "summary": "Streams n random bytes generated with given seed, at given chunk size per packet.",
        "parameters": [
          {
            "name": "numbytes",
            "in": "path",
            "required": true,
            "schema": {
              "type": "integer"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Bytes.",
            "content": {}
          }
        },
        "operationId": "getrange{numbytes}"
      }
    },
    "/redirect-to": {
      "get": {
        "tags": [
          "Redirects"
        ],
        "summary": "302/3XX Redirects to the given URL.",
        "parameters": [
          {
            "name": "url",
            "in": "query",
            "required": true,
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "status_code",
            "in": "query",
            "schema": {
              "type": "integer"
            }
          }
        ],
        "responses": {
          "302": {
            "description": "A redirection.",
            "content": {}
          }
        },
        "operationId": "getredirectto"
      },
      "put": {
        "tags": [
          "Redirects"
        ],
        "summary": "302/3XX Redirects to the given URL.",
        "requestBody": {
          "content": {
            "multipart/form-data": {
              "schema": {
                "required": [
                  "url"
                ],
                "properties": {
                  "url": {
                    "type": "string"
                  },
                  "status_code": {
                    "type": "integer",
                    "format": "int32"
                  }
                }
              }
            },
            "application/x-www-form-urlencoded": {
              "schema": {
                "required": [
                  "url"
                ],
                "properties": {
                  "url": {
                    "type": "string"
                  },
                  "status_code": {
                    "type": "integer",
                    "format": "int32"
                  }
                }
              }
            }
          },
          "required": true
        },
        "responses": {
          "302": {
            "description": "A redirection.",
            "content": {}
          }
        },
        "operationId": "putredirectto"
      },
      "post": {
        "tags": [
          "Redirects"
        ],
        "summary": "302/3XX Redirects to the given URL.",
        "requestBody": {
          "content": {
            "multipart/form-data": {
              "schema": {
                "required": [
                  "url"
                ],
                "properties": {
                  "url": {
                    "type": "string"
                  },
                  "status_code": {
                    "type": "integer",
                    "format": "int32"
                  }
                }
              }
            },
            "application/x-www-form-urlencoded": {
              "schema": {
                "required": [
                  "url"
                ],
                "properties": {
                  "url": {
                    "type": "string"
                  },
                  "status_code": {
                    "type": "integer",
                    "format": "int32"
                  }
                }
              }
            }
          },
          "required": true
        },
        "responses": {
          "302": {
            "description": "A redirection.",
            "content": {}
          }
        },
        "operationId": "postredirectto"
      },
      "delete": {
        "tags": [
          "Redirects"
        ],
        "summary": "302/3XX Redirects to the given URL.",
        "responses": {
          "302": {
            "description": "A redirection.",
            "content": {}
          }
        },
        "operationId": "deleteredirectto"
      },
      "patch": {
        "tags": [
          "Redirects"
        ],
        "summary": "302/3XX Redirects to the given URL.",
        "responses": {
          "302": {
            "description": "A redirection.",
            "content": {}
          }
        },
        "operationId": "patchredirectto"
      }
    },
    "/redirect/{n}": {
      "get": {
        "tags": [
          "Redirects"
        ],
        "summary": "302 Redirects n times.",
        "parameters": [
          {
            "name": "n",
            "in": "path",
            "required": true,
            "schema": {
              "type": "integer"
            }
          }
        ],
        "responses": {
          "302": {
            "description": "A redirection.",
            "content": {}
          }
        },
        "operationId": "getredirect{n}"
      }
    },
    "/relative-redirect/{n}": {
      "get": {
        "tags": [
          "Redirects"
        ],
        "summary": "Relatively 302 Redirects n times.",
        "parameters": [
          {
            "name": "n",
            "in": "path",
            "required": true,
            "schema": {
              "type": "integer"
            }
          }
        ],
        "responses": {
          "302": {
            "description": "A redirection.",
            "content": {}
          }
        },
        "operationId": "getrelativeredirect{n}"
      }
    },
    "/response-headers": {
      "get": {
        "tags": [
          "Response inspection"
        ],
        "summary": "Returns a set of response headers from the query string.",
        "parameters": [
          {
            "name": "freeform",
            "in": "query",
            "allowEmptyValue": true,
            "style": "form",
            "explode": true,
            "schema": {
              "type": "array",
              "items": {
                "type": "string"
              }
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Response headers",
            "content": {}
          }
        },
        "operationId": "getresponseheaders"
      },
      "post": {
        "tags": [
          "Response inspection"
        ],
        "summary": "Returns a set of response headers from the query string.",
        "parameters": [
          {
            "name": "freeform",
            "in": "query",
            "allowEmptyValue": true,
            "style": "form",
            "explode": true,
            "schema": {
              "type": "array",
              "items": {
                "type": "string"
              }
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Response headers",
            "content": {}
          }
        },
        "operationId": "postresponseheaders"
      }
    },
    "/robots.txt": {
      "get": {
        "tags": [
          "Response formats"
        ],
        "summary": "Returns some robots.txt rules.",
        "responses": {
          "200": {
            "description": "Robots file",
            "content": {}
          }
        },
        "operationId": "getrobots.txt"
      }
    },
    "/status/{codes}": {
      "get": {
        "tags": [
          "Status codes"
        ],
        "summary": "Return status code or random status code if more than one are given",
        "parameters": [
          {
            "name": "codes",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "100": {
            "description": "Informational responses",
            "content": {}
          },
          "200": {
            "description": "Success",
            "content": {}
          },
          "300": {
            "description": "Redirection",
            "content": {}
          },
          "400": {
            "description": "Client Errors",
            "content": {}
          },
          "500": {
            "description": "Server Errors",
            "content": {}
          }
        },
        "operationId": "getstatus{codes}"
      },
      "put": {
        "tags": [
          "Status codes"
        ],
        "summary": "Return status code or random status code if more than one are given",
        "parameters": [
          {
            "name": "codes",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "100": {
            "description": "Informational responses",
            "content": {}
          },
          "200": {
            "description": "Success",
            "content": {}
          },
          "300": {
            "description": "Redirection",
            "content": {}
          },
          "400": {
            "description": "Client Errors",
            "content": {}
          },
          "500": {
            "description": "Server Errors",
            "content": {}
          }
        },
        "operationId": "putstatus{codes}"
      },
      "post": {
        "tags": [
          "Status codes"
        ],
        "summary": "Return status code or random status code if more than one are given",
        "parameters": [
          {
            "name": "codes",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "100": {
            "description": "Informational responses",
            "content": {}
          },
          "200": {
            "description": "Success",
            "content": {}
          },
          "300": {
            "description": "Redirection",
            "content": {}
          },
          "400": {
            "description": "Client Errors",
            "content": {}
          },
          "500": {
            "description": "Server Errors",
            "content": {}
          }
        },
        "operationId": "poststatus{codes}"
      },
      "delete": {
        "tags": [
          "Status codes"
        ],
        "summary": "Return status code or random status code if more than one are given",
        "parameters": [
          {
            "name": "codes",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "100": {
            "description": "Informational responses",
            "content": {}
          },
          "200": {
            "description": "Success",
            "content": {}
          },
          "300": {
            "description": "Redirection",
            "content": {}
          },
          "400": {
            "description": "Client Errors",
            "content": {}
          },
          "500": {
            "description": "Server Errors",
            "content": {}
          }
        },
        "operationId": "deletestatus{codes}"
      },
      "patch": {
        "tags": [
          "Status codes"
        ],
        "summary": "Return status code or random status code if more than one are given",
        "parameters": [
          {
            "name": "codes",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "100": {
            "description": "Informational responses",
            "content": {}
          },
          "200": {
            "description": "Success",
            "content": {}
          },
          "300": {
            "description": "Redirection",
            "content": {}
          },
          "400": {
            "description": "Client Errors",
            "content": {}
          },
          "500": {
            "description": "Server Errors",
            "content": {}
          }
        },
        "operationId": "patchstatus{codes}"
      }
    },
    "/stream-bytes/{n}": {
      "get": {
        "tags": [
          "Dynamic data"
        ],
        "summary": "Streams n random bytes generated with given seed, at given chunk size per packet.",
        "parameters": [
          {
            "name": "n",
            "in": "path",
            "required": true,
            "schema": {
              "type": "integer"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Bytes.",
            "content": {}
          }
        },
        "operationId": "getstreambytes{n}"
      }
    },
    "/stream/{n}": {
      "get": {
        "tags": [
          "Dynamic data"
        ],
        "summary": "Stream n JSON responses",
        "parameters": [
          {
            "name": "n",
            "in": "path",
            "required": true,
            "schema": {
              "type": "integer"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Streamed JSON responses.",
            "content": {}
          }
        },
        "operationId": "getstream{n}"
      }
    },
    "/user-agent": {
      "get": {
        "tags": [
          "Request inspection"
        ],
        "summary": "Return the incoming requests's User-Agent header.",
        "responses": {
          "200": {
            "description": "The request's User-Agent header.",
            "content": {}
          }
        },
        "operationId": "getuseragent"
      }
    },
    "/uuid": {
      "get": {
        "tags": [
          "Dynamic data"
        ],
        "summary": "Return a UUID4.",
        "responses": {
          "200": {
            "description": "A UUID4.",
            "content": {}
          }
        },
        "operationId": "getuuid"
      }
    },
    "/xml": {
      "get": {
        "tags": [
          "Response formats"
        ],
        "summary": "Returns a simple XML document.",
        "responses": {
          "200": {
            "description": "An XML document.",
            "content": {}
          }
        },
        "operationId": "getxml"
      }
    }
  },
  "components": {}
}

const openAPIDefinition = dereferencedOpenAPIDefinition;
*/