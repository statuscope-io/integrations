#!/bin/bash

# A sample script that notifies Statuscope.io of running and enabled status of VirtualBox service
# Example cron entry: * * * * * cd /opt/scripts/ && ./check_service.sh

SERVICE_NAME=virtualbox

# Get the value indicating if the service is set to run on boot, 'active' is the value we want
is_enabled=`systemctl is-enabled $SERVICE_NAME`

# Get the value indicating if the service is running now, '0' is the value we want
service $SERVICE_NAME status &> /dev/null
is_running=$?

# Check values and craft a corresponding reason field
service_status="KO"
reason=""

# If service is not set to run at boot, assume a failure even if it's running now
if [ $is_enabled != 'enabled' ]; then
    reason="Service is not enabled to run at boot"
elif [ "$is_running" -ne 0 ]; then
    reason="Service is enabled but not running"
else
    reason="Service is enabled and running"
    service_status="OK"
fi

# Notify Statuscope.io
curl -H "Content-Type: application/json" \
     -X POST \
     -d '{"token":"1ba04f74", "status":"'"${service_status}"'", "reason": "'"${reason}"'"}' \
     https://www.statuscope.io/tasks/HwtnPK5JZSHkYzFpA

