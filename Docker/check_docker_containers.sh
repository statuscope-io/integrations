#!/bin/bash

# A sample script that notifies Statuscope.io of following features of docker containers
# - If they are running
# - If they have restarted for more than the user-set value
#
# Example cron entry: * * * * * cd /opt/scripts/ && ./check_docker_containers.sh

# Remote host, it is assumed that there is public-key auth set up
USER=username
HOSTNAME=hostname

# Restart count tolerance
RESTART_COUNT_MAX=10
# Containers that must be running
declare -a REQUIRED_CONTAINERS=('nginx' 'postgresql' 'monitoring' 'frontend')

# Check if containers are running
running_container_names=$(ssh $USER@$HOSTNAME "docker ps --format '{{.Names}}'")
echo "Following containers are running: $(echo $running_container_names | tr '\n' ' ')"
echo "Following containers are required: ${REQUIRED_CONTAINERS[@]}"
echo -e "\n"

for i in "${!REQUIRED_CONTAINERS[@]}"
do
    for container in $running_container_names
    do
        if [ "${REQUIRED_CONTAINERS[$i]}" == "$container" ]; then
            echo "Required container $container is running"
            # Remove the element from required list
            unset REQUIRED_CONTAINERS[$i]
        fi
    done
    # do whatever on $i
done

# Check if there are any remaning container names in the required list and alert if so
if [ ${#REQUIRED_CONTAINERS[@]} -eq 0 ]; then
    echo "All required containers are running"
    # Below we continue with the restart count check
else
    echo "Following required containers are not running: ${REQUIRED_CONTAINERS[@]}"
    # Signal missing required container to Statuscope.io
    curl -H "Content-Type: application/json" \
         -X POST \
         -d '{"token":"40990a6a", "status":"KO", "reason": "'"Missing containers: $(echo ${REQUIRED_CONTAINERS[@]})"'"}' \
         https://www.statuscope.io/tasks/dL7DcePXcF2Q4w79E
    # Exit here, this is grave enough
    exit 1
fi

# Now check if they are restarting for too many times
running_container_ids=$(ssh $USER@$HOSTNAME "docker ps -q" | tr '\n' ' ')
restart_counts=$(ssh $USER@$HOSTNAME "docker inspect --format='{{.Name}} {{.RestartCount}}' ${running_container_ids}")

# Collect names of failed containers
failed_containers=''
while read -r line; do
    container_name=$(echo $line | cut -d' ' -f1)
    restart_count=$(echo $line | cut -d' ' -f2)

    if [[ $restart_count -gt $RESTART_COUNT_MAX ]]; then
        echo "$container_name restarted more than $RESTART_COUNT_MAX times"
        failed_containers="$failed_containers $container_name"

    fi
done <<< "$restart_counts"

if [ -n "$failed_containers" ]; then
    echo "There are containers restarting too often, signalling to Statuscope.io"

    # Signal these containers to Statuscope.io
    curl -H "Content-Type: application/json" \
         -X POST \
         -d '{"token":"40990a6a", "status":"KO", "reason": "'"Restarting too often: $failed_containers"'"}' \
         https://www.statuscope.io/tasks/dL7DcePXcF2Q4w79E
else
    # Signal an OK status for heartbeat update
    curl -H "Content-Type: application/json" \
         -X POST \
         -d '{"token":"40990a6a", "status":"OK"}' \
         https://www.statuscope.io/tasks/dL7DcePXcF2Q4w79E
fi

echo "Done."

