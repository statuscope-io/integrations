#!/bin/bash

# A sample script that notifies Statuscope.io of the status of an FTP server
# Example cron entry: */5 * * * * cd /opt/scripts/ && ./check_ftp_server.sh ftp.local.net HwtnPK5JZSHkYzFpA 1ba04f74

# Be sure all the parameters are given
if [ "$#" -ne 3 ]; then
    echo "Tip: ./check_ftp_server.sh <ftp_server> <statuscopeJobId> <statuscopeToken>"
    echo "Example: ./check_ftp_server.sh ftp.local.net HwtnPK5JZSHkYzFpA 1ba04f74"
    exit 1
fi

FTP_SERVER=$1
TASK_ID=$2
TOKEN=$3

# Check values and craft a corresponding reason field
ftp_server_status="KO"
reason=""

# Check if FTP port is open
status=$(nc -z -w1 $FTP_SERVER 21 2>&1)
status_code=$?

if [[ $status_code == '0' ]]; then
    echo "FTP server is UP"

    # We don't really need a reason field for OK heartbeats so set only the status field
    ftp_server_status="OK"
else
    echo "FTP server is DOWN"

    # Update reason with the output of nc, so that on Statuscope Panel we will have 
    # "nc: getaddrinfo for host ftp.dlptest2.com port 21: Name or service not known", for example
    # Note that we're removing double quotes below
    reason=$(echo $status | tr -d '"')
fi

# Notify Statuscope.io
curl -H "Content-Type: application/json" \
     -X POST \
     -d '{"token":"'"${TOKEN}"'", "status":"'"${ftp_server_status}"'", "reason": "'"${reason}"'"}' \
     https://www.statuscope.io/tasks/${TASK_ID}

