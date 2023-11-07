# generate a client cert and key
```
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 3650 -nodes -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=CommonNameOrHostname"
```
# use openssl to test
```
true | openssl s_client -connect play.clients.int-nft.peacocktv.com:443 \
-servername play.clients.int-nft.peacocktv.com \
-tls1_3 \
-ciphersuites TLS_AES_256_GCM_SHA384 \
-cert "CERTFILENAME" \
-key "KEYFILENAME"
```
