#!/bin/bash

# A sample script that notifies Statuscope.io of possible vulnerabilities of a WordPress site
# Example cron entry: 0 * * * * /opt/statuscope.io/security/check_wordpress_site.sh <token> <task_id> <url>

# Verify parameters
if [ "$#" -ne 3 ]; then
    echo "Tip: ./check_wordpress_site.sh <token> <jobId> <url>"
    echo "Example: ./check_wordpress_site.sh 1ba04f74 HwtnPK5JZSHkYzFpA https://www.southernrecipies.com/"
    exit 1
fi

TOKEN=$1
TASK_ID=$2
URL=$3

# Update vulnerability database of wpscan
wpscan --update

# Run a scan with wpscan then use jq to count the number of vulnerabilities found
number_of_vulnerabilities=$(wpscan --url ${URL} --format json | jq '.version.vulnerabilities | length')

if [[ number_of_vulnerabilities -gt 0 ]]; then
    echo "${number_of_vulnerabilities} vulnerabilities found on ${URL}"
    curl -H "Content-Type: application/json" \
         -X POST \
         -d '{"token":"'"${TOKEN}"'", "status":"KO", "reason": "'"${number_of_vulnerabilities} vulnerabilities found"'"}' \
         https://api.statuscope.io/tasks/${TASK_ID}
else
    echo "No vulnerabilities found on ${URL}"
    curl -H "Content-Type: application/json" \
         -X POST \
         -d '{"token":"'"${TOKEN}"'", "status":"OK", "reason": "'"No vulnerabilities found"'"}' \
         https://api.statuscope.io/tasks/${TASK_ID}
fi

