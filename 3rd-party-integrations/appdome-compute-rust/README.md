# AppDome integration


## AppDome
1. Set and save protected_secret, compromised_secret
2. Set and save the session public key and private key. TODO provide `openssl` example to generate keys.
3. Configure Fastly NGWAF with AppDome recommended ruleset

## Fastly Specific
1. Set up NGWAF Edge deployment using Fastly Compute (https://www.fastly.com/documentation/solutions/tutorials/next-gen-waf-compute/)
2. Place session private key in ./src/sessionprivatekey.pem
3. Update the protected_secret, compromised_secret. TODO. Fastly should use a data store for this information.
4. (Optional) Configure mTLS with Fastly.





