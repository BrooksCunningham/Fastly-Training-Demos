#!/bin/sh
sigsci-agent & 
nginx -g "daemon off; error_log /dev/stdout info;"
