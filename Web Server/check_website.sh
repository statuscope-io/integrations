#!/bin/bash

# A sample script that notifies Statuscope.io of the status of a website
# Note that this is for intranet sites, for public websites please add a Web Task
# See https://www.statuscope.io/faq#website_checks
# Example cron entry: */5 * * * * cd /opt/scripts/ && ./check_website.sh jenkins.intranet HwtnPK5JZSHkYzFpA 1ba04f74

# Be sure all the parameters are given
if [ "$#" -ne 3 ]; then
    echo "Tip: ./check_website.sh <website> <statuscopeJobId> <statuscopeToken>"
    echo "Example: ./check_website.sh jenkins.local.com HwtnPK5JZSHkYzFpA 1ba04f74"
    exit 1
fi

WEBSITE=$1
TASK_ID=$2
TOKEN=$3

# Try to connect to the website and get the HTTP status code
# Note: If you want only HEAD instead of GET, add -I
status_code=`curl -sL -w "%{http_code}\\n" "$WEBSITE" -o /dev/null`

# Check values and craft a corresponding reason field
website_status="KO"
reason=""

# See if we have HTTP 200
if [ $status_code != '200' ]; then
    reason="Jenkins returned $status_code"
else
    # We don't really need a reason field for OK heartbeats
    reason=""
    website_status="OK"
fi

# Notify Statuscope.io
curl -H "Content-Type: application/json" \
     -X POST \
     -d '{"token":"'"${TOKEN}"'", "status":"'"${website_status}"'", "reason": "'"${reason}"'"}' \
     https://www.statuscope.io/tasks/${TASK_ID}

