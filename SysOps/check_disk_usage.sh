#!/bin/bash

# A sample script that notifies Statuscope.io of available disk space in /home
# Example cron entry: 0 * * * * cd /opt/scripts/ && ./check_disk_space.sh

disk_usage=$(df --output=pcent /home | tr -dc '0-9')

if [[ disk_usage -gt 90 ]]; then
    echo "Disk usage of /home has passed 90%"
    curl -H "Content-Type: application/json" \
         -X POST \
         -d '{"token":"95ef3bf7", "status":"KO", "reason": "Disk usage of /home is over 90%"}' \
         https://www.statuscope.io/tasks/qMcQax5AczvAfwcXW
else
    echo "Disk usage of /home is less than 90%"
    curl -H "Content-Type: application/json" \
         -X POST \
         -d '{"token":"95ef3bf7", "status":"OK", "reason": "'"/home disk usage is at ${disk_usage}%"'"}' \
         https://www.statuscope.io/tasks/qMcQax5AczvAfwcXW
fi

