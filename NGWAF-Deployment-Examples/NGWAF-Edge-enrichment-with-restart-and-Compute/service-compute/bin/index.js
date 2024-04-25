/******/ (() => { // webpackBootstrap
/******/ 	"use strict";
/******/ 	// The require scope
/******/ 	var __webpack_require__ = {};
/******/ 	
/************************************************************************/
/******/ 	/* webpack/runtime/make namespace object */
/******/ 	(() => {
/******/ 		// define __esModule on exports
/******/ 		__webpack_require__.r = (exports) => {
/******/ 			if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 				Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 			}
/******/ 			Object.defineProperty(exports, '__esModule', { value: true });
/******/ 		};
/******/ 	})();
/******/ 	
/************************************************************************/
var __webpack_exports__ = {};
// ESM COMPAT FLAG
__webpack_require__.r(__webpack_exports__);

;// CONCATENATED MODULE: external "fastly:env"
const external_fastly_env_namespaceObject = require("fastly:env");
;// CONCATENATED MODULE: external "fastly:kv-store"
const external_fastly_kv_store_namespaceObject = require("fastly:kv-store");
;// CONCATENATED MODULE: ./src/shared.js
/// <reference types="@fastly/js-compute" />

// Shared code I don't want cluttering up main



// Wrap some error handling and logging around the default methods.
async function kv_get(kv_store, KEY, DEBUG) {
    let kv_key = null;
    
    let start = performance.now();
    try {
      kv_key = await kv_store.get(KEY);
    } catch (error) {
      console.log("kv_get.get:",error);
      return null;
    }
  
    if(kv_key === null) {
      console.log("kv_get: key not found:", KEY);
      return null;
    } 

    // Fulfill any pending promise before returning, so we can have meaningful timings.
    let kv_body = await kv_key.json();
    DEBUG ? console.log("KV Key Fetch in",performance.now()-start,"ms :",KEY):null;

    return kv_body;
}

;// CONCATENATED MODULE: ./src/index.js
//! Default Compute template program.

/// <reference types="@fastly/js-compute" />
// import { CacheOverride } from "fastly:cache-override";
// import { Logger } from "fastly:logger";






/*
KV store will maintain the list of IPs
Webhook receipt - add ip as key, { insert time, expire time } as value.
Check maintenance key (value of last_run_time), if > 24 hours elapsed, perform keyspace maintenance (removal of expiries, etc) after request is satisfied.
Query should return 200 or 404 status (as example) for block/non-block to VCL
Perhaps maintenance check should be here, rather than on webhook, since it’s more likely to be called regularly.
*/

// The entry point for your application.
//
// Use this fetch event listener to define your main request handling logic. It could be
// used to route based on the request properties (such as method or path), send
// the request to a backend, make completely new requests, and/or generate
// synthetic responses.

addEventListener("fetch", (event) => event.respondWith(handleRequest(event)));

async function handleRequest(event) {
  // Get the client request.
  let req = event.request;
  let url = new URL(req.url);
  let VERSION = (0,external_fastly_env_namespaceObject.env)("FASTLY_SERVICE_VERSION");
  let HOST = (0,external_fastly_env_namespaceObject.env)("FASTLY_HOSTNAME");
  let LOCAL = 0;
  let DEBUG = 0;
  let event_client_ip = event.client.address;

  // Set Debug Flag - CHANGE THIS FOR YOUR SYSTEM.
  if(req.headers.get("Fastly-Debug") == "10145-bdn") { DEBUG = 1; }
  let client_ip = req.headers.get("FASTLY-CLIENT-IP");

  // Handle things that are specific to running locally
  if (!client_ip) { client_ip = event_client_ip; }
  if(HOST === "localhost") {
    LOCAL = 1;
    VERSION = "L";
  }
      
  console.log("Service Version:",VERSION,"running on",HOST,"from",client_ip,"(",event_client_ip,") at",Date().toString());

  // Filter requests that have unexpected methods.
  if (["PUT", "PATCH", "DELETE"].includes(req.method)) {
    return new Response("This method is not allowed", {
      status: 405,
    });
  }
 
  // Empty 200 for this. Clutters logs up with errors otherwise.
  if(url.pathname == "/favicon.ico") {
    return new Response("", {
      status: 200,
      headers: new Headers({ 
        "cache-control": "s-maxage=604800, max-age=604800" })
    });  
  }

  var ip_list;

  // Open the KV store  
  try {
    ip_list = new external_fastly_kv_store_namespaceObject.KVStore('ip_blocklist');
  } catch(error) {
    console.log("Unable to open blocklist KV:",error);
  }

  // Check all requests, regardless of path. This is to prevent abuse of the API endpoint by a blocked
  // address.
  let ip_entry = await kv_get(ip_list, client_ip, DEBUG);
  let now = Date.now();

  if(ip_entry && ip_entry["expires"] >= now) {
    DEBUG ? console.log("Entry present and not expired, blocking:", client_ip, now, ip_entry["expires"]):null;
    return new Response("Ok", {
      status: 404,
      headers: new Headers({ "Content-Type": "text/html; charset=utf-8" }),
    });
  } else if (ip_entry && ip_entry["expires"] < now) {
      // If we have a key, but it's expired - remove it from they KV store
      DEBUG ? console.log("Found an entry, but it's expired, deleting:",client_ip, now, ip_entry["expires"]):null;
      await ip_list.delete(client_ip);
  }
  
  // Add an IP to the blocklist
  if (url.pathname == "/add" && req.method == "POST") {
    // Add an ip to the KV store.
    // ip, { insert_time, expire_time }
    // If key is present in KV, update the existing k/v pair
    // If it is not preset, then add it in
    // 7 day duration for block
    // Test with : 
    // fastly compute serve
    // curl -q --data @payload.json "http://127.0.0.1:7676/add"
    
    // Populate the JSON object in memory from the body of the request.
    // relevant fields :
    // @timestamp, Vendor.client_ip, client.ip, source.ip
    //
    let payload;

    try {
      payload = await req.json();
    } catch(error) {
      console.log("Unexpected error:", error);
      return new Response("An unexpected error has occurred.", {
        status: 500,
        headers: new Headers({ "Content-Type": "text/html; charset=utf-8" }),
      });
    }
   
    let ip_entry = await kv_get(ip_list, payload["client.ip"], DEBUG);
    let now = Date.now();
    let expires = now;

    if(DEBUG) {
      expires = now + 5000;
    } else {
      expires = now + 604800000;
    }
    let value = '{ "added": '+now+',"expires": '+expires+' }';

    if(ip_entry == null) {
      DEBUG ? console.log("New entry:", payload["client.ip"], now, expires):null;
    } else {
      DEBUG ? console.log("Entry found, updating:", ip_entry["added"], ip_entry["expires"],"|",now, expires):null;
    }

    // Add or update the existing value in place.
    try {
      await ip_list.put(payload["client.ip"], value);
    } catch (error) {
      console.log("unexpted error:kv.put", error);
    }

    return new Response("Ok", {
      status: 200,
      headers: new Headers({ "Content-Type": "text/html; charset=utf-8" }),
    });

  } else {
    // For future expansion/addition of functionality.
  }

  // Catch all other requests and return a 200 if we haven't been blocked.
  return new Response("Ok", {
    status: 200,
    headers: new Headers({ "Content-Type": "text/html; charset=utf-8" }),
  });
}
var __webpack_export_target__ = this;
for(var i in __webpack_exports__) __webpack_export_target__[i] = __webpack_exports__[i];
if(__webpack_exports__.__esModule) Object.defineProperty(__webpack_export_target__, "__esModule", { value: true });
/******/ })()
;