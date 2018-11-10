#!/bin/bash

# A sample script that notifies Statuscope.io of available disk space in /home of a remote computer
# Example cron entry: 0 * * * * /opt/statuscope.io/disk/check_remote_disk_space.sh root 88.23.12.33 <token> <task_id> /home 90
# Note that this script assumes that there is public key authentication set up for this destination

# Verify parameters
if [ "$#" -ne 6 ]; then
    echo "Tip: ./check_remote_disk_space.sh <remoteUser> <remoteIpOrHostname> <token> <jobId> <partition> <usageWarningThreshold>"
    echo "Example: ./check_website.sh root 88.23.12.33 1ba04f74 HwtnPK5JZSHkYzFpA /home 90"
    exit 1
fi

USER=$1
HOSTNAME=$2
TOKEN=$3
TASK_ID=$4
PARTITION=$5
THRESHOLD=$6

disk_usage=$(ssh ${USER}@${HOSTNAME} "df --output=pcent ${PARTITION} | tr -dc '0-9'")

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

