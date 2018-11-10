#!/bin/bash

# A sample script that notifies Statuscope.io of available disk space in /home
# Example cron entry: 0 * * * * /opt/statuscope.io/disk/check_disk_space.sh <token> <task_id> /home 90

# Verify parameters
if [ "$#" -ne 4 ]; then
    echo "Tip: ./check_disk_space.sh <token> <jobId> <partition> <usageWarningThreshold>"
    echo "Example: ./check_website.sh 1ba04f74 HwtnPK5JZSHkYzFpA /home 90"
    exit 1
fi

TOKEN=$1
TASK_ID=$2
PARTITION=$3
THRESHOLD=$4

echo "token=${TOKEN} task_id=${TASK_ID} part=${PARTITION} threshold=${THRESHOLD}"

disk_usage=$(df --output=pcent ${PARTITION} | tr -dc '0-9')

if [[ disk_usage -gt $THRESHOLD ]]; then
    echo "Disk usage of ${PARTITION} has passed ${THRESHOLD}%"
    curl -H "Content-Type: application/json" \
         -X POST \
         -d '{"token":"'"${TOKEN}"'", "status":"KO", "reason": "'"Disk usage of ${PARTITION} is over ${THRESHOLD}%"'"}' \
         https://api.statuscope.io/tasks/${TASK_ID}
else
    echo "Disk usage of ${PARTITION} is less than ${THRESHOLD}%"
    curl -H "Content-Type: application/json" \
         -X POST \
         -d '{"token":"'"${TOKEN}"'", "status":"OK", "reason": "'"${PARTITION} disk usage is at ${disk_usage}%"'"}' \
         https://api.statuscope.io/tasks/${TASK_ID}
fi

