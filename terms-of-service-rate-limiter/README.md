# Rate limiting for different tiers of users

## Free tier example
```
for i in {1..25}; do printf "${i}, " ; http https://terms-of-service-rate-limiter.edgecompute.app/anything/123 product-tier:free api-key:userkey4 foo=bar -p=h | head -n1 ; sleep 2 ; done
1, HTTP/1.1 200
2, HTTP/1.1 200
3, HTTP/1.1 200
4, HTTP/1.1 200
5, HTTP/1.1 200
6, HTTP/1.1 417
7, HTTP/1.1 417
8, HTTP/1.1 417
9, HTTP/1.1 417
10, HTTP/1.1 417
...
```
## Gold tier example
```
! for i in {1..25}; do printf "${i}, " ; http https://terms-of-service-rate-limiter.edgecompute.app/anything/123 product-tier:gold api-key:userkey2 foo=bar -p=h | head -n1 ; sleep 2 ; done
1, HTTP/1.1 200
2, HTTP/1.1 200
...
10, HTTP/1.1 200
11, HTTP/1.1 417
12, HTTP/1.1 417
...
```

## Platinum tier example
```
 for i in {1..25}; do printf "${i}, " ; http https://terms-of-service-rate-limiter.edgecompute.app/anything/123 product-tier:platinum api-key:userkey5 foo=bar -p=h | head -n1 ; sleep 2 ; done
1, HTTP/1.1 200
2, HTTP/1.1 200
...
20, HTTP/1.1 200
21, HTTP/1.1 417
...
25, HTTP/1.1 417
```