/// <reference types="@fastly/js-compute" />

import { env } from "fastly:env";
import { includeBytes } from "fastly:experimental";
import { OpenAPIValidator } from "openapi-backend";

const textDecoder = new TextDecoder();

// A valid and fully-dereferenced OpenAPI 3.x definition.
const openAPIDefinition = JSON.parse(textDecoder.decode(includeBytes('src/definition.json')));

// If true, invalid requests will be rejected with a 400 response.
// Otherwise, they will be forwarded to the origin after OpenAPI validation errors are logged.
const REJECT_INVALID_REQUESTS = true;
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

  // Validate the request.
  const reqValidationResult = await validateRequest(req, openAPIValidator);
  console.log(reqValidationResult);

  // Forward request to the origin
  let backendResp = await fetch(req, { backend: BACKEND });

  // clone the response to use for validation
  let responseValidationResult = {};
  [backendResp, responseValidationResult] = await validateResponse(backendResp, openAPIValidator, reqValidationResult.operationId);

  console.log(responseValidationResult);

  // Return the original backend response back to the client.
  return backendResp
}

async function validateRequest(req, openAPIValidator) {
  try {
    const req_clone = req.clone();
    const url = new URL(req_clone.url);

    // Clones the request to retreive the body of the request.
    const reqBodyText = await req_clone.text();
    const normalizedForValidation = {
      method: req_clone.method,
      // path of the request
      path: url.pathname,
      // HTTP request headers
      headers: Object.fromEntries(req_clone.headers.entries()),
      // parsed query parameters
      query: Object.fromEntries(url.searchParams.entries()),
      // the request body is not available for a GET request
      body: reqBodyText,
    };

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
    // If the request is valid for the spec, then return the operation ID that may be used for the response validation.
    return { isValid: true, "operationId": operation.operationId }

  } catch (error) {
    // Handle errors, including when an operation is not matched.
    console.error("OpenAPI request validation failed", error);
    if (REJECT_INVALID_REQUESTS) {
      // Send a synthetic 400 response.
      return error
      // return new Response("Bad Request", { status: 400 });
    }
    return { "isValid": false, "operationId": "nil" }
  }
}

async function validateResponse(response, openAPIValidator, operationId) {

  // Take care! .text() will consume the entire body into memory!
  let respBodyText = await response.text();
  let newResp = new Response(respBodyText);

  // Only evaluate requests that are formated as JSON from the origin for this example
  if (response.headers.get("content-type").includes("json")) {
    try {
      // Only do the response body check if the response body is valid JSON.
      // console.log(`operation.operationId:`, operationId);
      const validateResponse = openAPIValidator.validateResponse(JSON.parse(respBodyText), operationId);

      if (validateResponse.errors) {
        // there were errors, then throw an error
        // console.log(validateResponse.errors);
        throw new Error("Invalid RESPONSE");
      }
      // console.log(`Inspected response: TRUE`);

      return [newResp, { "isValid": true, "error": "None" }]
    } catch (error) {
      // Handle errors, including when an operation is not matched.
      // console.error("OpenAPI RESPONSE validation failed", error);
      // return the original response and status on the response validation
      return [newResp, { "isValid": false, "error": error }]
    }
  }
  // return when there is no response inspected
  return [newResp, { "isValid": false, "error": "None" }]
}
