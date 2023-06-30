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
  const reqBodyText = await req.text();
  let operation;

  // Validate the request.
  try {
    const url = new URL(req.url);
    // Build a normalized Request object to pass to the OpenAPI validator.
    // https://github.com/anttiviljami/openapi-backend/blob/master/DOCS.md#request-object
    console.log(`req method: `,req.method);
    let normalizedForValidation = {};
    if (req.method == "GET") {
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
      console.log("POST if'ed")
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
    operation = openAPIValidator.router.matchOperation(
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
  } catch (error) {
    // Handle errors, including when an operation is not matched.
    console.error("OpenAPI request validation failed", error);
    if (REJECT_INVALID_REQUESTS) {
      // Send a synthetic 400 response.
      return new Response("Bad Request because of request validation", { status: 400 });
    }
  }

  // capture the response for response validation
  let backendResponse = new Response;
  
  if (req.method == "GET") {
    backendResponse = await fetch(req, {
      backend: BACKEND,
    });
  }
  if (req.method == "POST") {
    backendResponse = await fetch(req, {
      backend: BACKEND,
      body: reqBodyText
    });
  }


  // /*
  // Take care! .text() will consume the entire body into memory!
  let respBodyText = await backendResponse.text();

  // Only do the response body check if the response body is valid JSON.
  if (tryParseJSONObject(respBodyText) != false){
    console.log(`operation.operationId`, operation.operationId);
    // respBodyText = JSON.parse(respBodyText);
    const validateResponse = openAPIValidator.validateResponse(JSON.parse(respBodyText), operation.operationId);

    try {
      // console.log(validateResponse);
      if (validateResponse.errors) {
        // there were errors
        console.log(validateResponse.errors);
        throw new Error("Invalid RESPONSE");
      }
    } catch (error) {
      // Handle errors, including when an operation is not matched.
      console.error("OpenAPI RESPONSE validation failed", error);
      // Send a synthetic 400 response.
      return new Response("RESPONSE validation error", { status: 400 });
    }
  }
  
  // Return the response to the client.
  return new Response(respBodyText, backendResponse);
}

function tryParseJSONObject (jsonString){
  try {
      var o = JSON.parse(jsonString);

      // Handle non-exception-throwing cases:
      // Neither JSON.parse(false) or JSON.parse(1234) throw errors, hence the type-checking,
      // but... JSON.parse(null) returns null, and typeof null === "object", 
      // so we must check for that, too. Thankfully, null is falsey, so this suffices:
      if (o && typeof o === "object") {
          return o;
      }
  }
  catch (e) { }

  return false;
};