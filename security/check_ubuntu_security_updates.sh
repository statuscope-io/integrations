#!/bin/bash
  
# A sample script that notifies Statuscope.io if there are security updates to install on an Ubuntu box
# Note that this script requires owner to be sudo
# Example cron entry: 0 * * * * /opt/statuscope.io/security/check_ubuntu_security_updates.sh <token> <task_id>

# Verify parameters
if [ "$#" -ne 2 ]; then
    echo "Tip: ./check_ubuntu_security_updates.sh <token> <jobId>"
    echo "Example: ./check_ubuntu_security_updates.sh 1ba04f74 HwtnPK5JZSHkYzFpA"
    exit 1
fi

TOKEN=$1
TASK_ID=$2

# Update package list first
sudo apt update

# Find the number of security updates available
number_of_security_updates=$(sudo apt list --upgradable 2>/dev/null | grep "$(lsb_release -cs)-security" | wc -l)

if [[ number_of_security_updates -gt 0 ]]; then
    echo "${number_of_security_updates} security update(s) are available"
    curl -H "Content-Type: application/json" \
         -X POST \
         -d '{"token":"'"${TOKEN}"'", "status":"KO", "reason": "'"${number_of_security_updates} security update(s) found"'"}' \
         https://api.statuscope.io/tasks/${TASK_ID}
else
    echo "No security updates found"
    curl -H "Content-Type: application/json" \
         -X POST \
         -d '{"token":"'"${TOKEN}"'", "status":"OK", "reason": "'"No security updates found"'"}' \
         https://api.statuscope.io/tasks/${TASK_ID}
fi
