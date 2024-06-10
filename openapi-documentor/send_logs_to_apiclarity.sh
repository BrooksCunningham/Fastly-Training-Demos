#!/bin/bash

# Define the log file to monitor
logfile="./logfile.log"

# Use tail -f to follow the log file
tail -f "$logfile" | while IFS= read -r line
do
    # Extract the URL from the third column using awk
    # url=$(echo "$line" | awk -F, '{print $3}')
    api_clarity_trace=$(echo "$line" | cut -f2)
    
    # Use curl to send a POST to the API Clarity endpoint

    # echo $api_clarity_trace | jq

    # echo "curl -X POST http://127.0.0.1:9001/api/telemetry -H 'content-type:application/json' -H X-Trace-Source-Token:$TRACE_SOURCE_TOKEN -d '$api_clarity_trace' -iv"

    curl -X POST "http://127.0.0.1:9000/api/telemetry" \
        -H 'content-type:application/json' -H X-Trace-Source-Token:$TRACE_SOURCE_TOKEN \
        -d "$api_clarity_trace" -iv
    
done

