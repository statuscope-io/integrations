#!/bin/bash

# A sample script that notifies Statuscope.io of used disk space of a mongodb server
# Example cron entry: 0 * * * * /opt/statuscope.io/disk/check_mongodb_disk_usage.sh <mongoURL> <mongoUser> <mongoPwd> <token> <taskId> <thresholdInBytes>
# Note that this script expects password in cleartext so do not add it to crontasks of a shared account

# Verify parameters
if [ "$#" -ne 6 ]; then
    echo "Tip: ./check_mongodb_disk_usage.sh <mongoURL> <mongoUser> <mongoPwd> <token> <taskId> <thresholdInMegabytes>"
    echo "Example: ./check_mongodb_disk_usage.sh 10.10.0.0:27017/testdb testuser sknEzEc8apLP41Zg 1ba012f74 HwPK5JZSHkYzFpA 1024"
    exit 1
fi

MONGO_URL=$1
MONGO_USER=$2
MONGO_PWD=$3
TASK_TOKEN=$4
TASK_ID=$5
THRESHOLD=$6

mongo_disk_usage=$(mongo --quiet --eval 'db.stats()' $MONGO_URL -u $MONGO_USER -p $MONGO_PWD | jq '.storageSize')

mongo_disk_usage_in_mb=$(($mongo_disk_usage / 1048576))
echo "Mongo uses $mongo_disk_usage_in_mb megabytes"

if [[ mongo_disk_usage_in_mb -gt $THRESHOLD ]]; then
    echo "Disk usage of MongoDB has passed ${THRESHOLD}"
    curl -d "token=$TASK_TOKEN&status=KO&reason=MongoDB uses $mongo_disk_usage_in_mb MB" https://api.statuscope.io/tasks/$TASK_ID
else
    echo "Disk usage of MongoDB is less than ${THRESHOLD}"
    curl -d "token=$TASK_TOKEN&status=OK&reason=MongoDB uses $mongo_disk_usage_in_mb MB" https://api.statuscope.io/tasks/$TASK_ID
fi

