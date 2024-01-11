#!/bin/sh -eux

/usr/sbin/sigsci-agent --envoy-grpc-address=127.0.0.1:8000 --envoy-expect-response-data=1 --waf-data-log "/dev/stdout"  &
/usr/bin/envoy -c /etc/envoy/envoy.yaml
