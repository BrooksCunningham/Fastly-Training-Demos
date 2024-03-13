# ERL Compute Demo

```
! fastly log-tail
INFO: Managed logging enabled on service SERVICEID

stdout | 85fc04b6 | {"is_blocked":false,"pb_1_lookup":false,"rc_1_lookup_count":9}
stdout | a34b59eb | {"is_blocked":false,"pb_1_lookup":false,"rc_1_lookup_count":3}
stdout | 38ab2e79 | {"is_blocked":false,"pb_1_lookup":false,"rc_1_lookup_count":4}
stdout | d339a633 | {"is_blocked":false,"pb_1_lookup":false,"rc_1_lookup_count":1}
stdout | 5d412865 | {"is_blocked":false,"pb_1_lookup":false,"rc_1_lookup_count":3}
stdout | afb0c34b | {"is_blocked":true,"pb_1_lookup":true,"rc_1_lookup_count":11}
stdout | f1f47c93 | {"is_blocked":false,"pb_1_lookup":false,"rc_1_lookup_count":10}
stdout | 8d20b9f0 | {"is_blocked":true,"pb_1_lookup":true,"rc_1_lookup_count":13}
stdout | 4ea549a0 | {"is_blocked":true,"pb_1_lookup":true,"rc_1_lookup_count":12}
```

Rate limiting with URL as RL identifier.
```
echo "GET https://yourdomainhere.edgecompute.app/bc-e" | vegeta attack -rate=15/s -header "vegeta-test:ratelimittest1" -duration=10s  | vegeta report -type=text
Requests      [total, rate, throughput]         150, 15.10, 1.00
Duration      [total, attack, wait]             9.955s, 9.934s, 21.877ms
Latencies     [min, mean, 50, 90, 95, 99, max]  19.204ms, 25.365ms, 22.64ms, 26.132ms, 31.634ms, 96.042ms, 159.782ms
Bytes In      [total, mean]                     10141, 67.61
Bytes Out     [total, mean]                     0, 0.00
Success       [ratio]                           6.67%
Status Codes  [code:count]                      200:10  429:140
Error Set:
429 Too Many Request
```
