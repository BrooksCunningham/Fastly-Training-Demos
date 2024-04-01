/// <reference types="@fastly/js-compute" />

// Shared code I don't want cluttering up main
import { KVStore } from "fastly:kv-store";


// Wrap some error handling and logging around the default methods.
export async function kv_get(kv_store, KEY, DEBUG) {
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
