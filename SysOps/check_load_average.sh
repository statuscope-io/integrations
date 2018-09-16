#!/bin/bash

# A sample script that notifies Statuscope.io of current load average on a remote host
# Example cron entry: * * * * * cd /opt/scripts/ && ./check_load_average.sh

# Remote host
USER=username
HOSTNAME=hostname

# Load average threshold to alert
LOAD_AVERAGE_MAX=10

# Preferably have public-key auth set up for easier access
load_average=$(ssh $USER@$HOSTNAME "cat /proc/loadavg")

# Get each of 3 columns to have 1-minute, 5-minute, and 15-minute average, respectively
min1_average=$(echo $load_average | cut -d' ' -f1)
min5_average=$(echo $load_average | cut -d' ' -f2)
min15_average=$(echo $load_average | cut -d' ' -f3)

echo "Load average: 1min=$min1_average 5min=$min5_average 15min=$min15_average"

# Here we check only the 1-minute average, but we report all of them to Statuscope.io in the 'reason' field
if (( $(echo "$min1_average > $LOAD_AVERAGE_MAX" | bc -l) )); then
    echo "1 minute load average is more than $LOAD_AVERAGE_MAX"

    curl -H "Content-Type: application/json" \
         -X POST \
         -d '{"token":"39fb8bb0", "status":"KO", "reason": "'"1min=${min1_average} 5min=${min5_average} 15min=${min15_average}"'"}' \
         https://www.statuscope.io/tasks/yNYszDHHzDKYqJJAn
else
    echo "1 minute load average is less than $LOAD_AVERAGE_MAX"

    curl -H "Content-Type: application/json" \
         -X POST \
         -d '{"token":"39fb8bb0", "status":"OK", "reason": "'"1min=${min1_average} 5min=${min5_average} 15min=${min15_average}"'"}' \
         https://www.statuscope.io/tasks/yNYszDHHzDKYqJJAn
fi

