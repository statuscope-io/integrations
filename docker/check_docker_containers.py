#! /usr/bin/env python
# coding=utf-8

from datetime import date
import argparse
import logging
import os
import sys
import json

# Add internal library to paths
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '_lib'))

# Get a logger and set log level to INFO
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Import internal modules
from sccore import scutil, sctask

if __name__ != '__main__':
    logger.error('This script is to be run, not to be imported')
    sys.exit(0)

###############################################################################
# Process command line arguments
###############################################################################
parser = argparse.ArgumentParser()
parser.add_argument('--container', help="Name of the container as shown in 'docker ps'", action='append', nargs='+', required=True)
parser.add_argument('--uptime', help="Uptime limit in minutes where below this number we fire an alarm", required=True)
parser.add_argument('--token', help="Statuscope.io user/task token", required=True)
parser.add_argument('--taskid', help="Statuscope.io task ID", required=True)
flags = parser.parse_args()

logger.info("Given flags are: {}".format(flags))

###############################################################################
# Find IDs and names of running containers
###############################################################################
running_container_ids_command = []
running_container_ids_command.append("docker")
running_container_ids_command.append("ps")
running_container_ids_command.append("--format")
running_container_ids_command.append("'{{.ID}} {{.Names}}'")
result = scutil.get_local_command_output(running_container_ids_command)

# Check exit code
if result[0] != 0:
    reason = "Failed to get list of running containers"
    sctask.signal_task_failure(flags.token, flags.taskid, reason=reason)
    sys.exit(1)

# Result is in stdout element
running_containers = list()
for line in result[1].split(os.linesep):
    if line:
        # If the line is valid, add ID and name of the container to the list
        running_containers.append(tuple(line.replace('\'', '').split()))

logger.debug("Running containers: {}".format(running_containers))

###############################################################################
# Prepare list of IDs and names
###############################################################################
running_container_ids = [ container[0] for container in running_containers ]
logger.debug("Running container IDs are {}".format(running_container_ids))
running_container_names = [ container[1] for container in running_containers ]
logger.debug("Running container names are {}".format(running_container_names))

###############################################################################
# Iterate containers given by the user and check if there are any missing
###############################################################################
missing_containers = []
for required_container in flags.container:
    # argparse will deliver us each --container instance in a list, so pick the first element
    _required_container = required_container[0]
    logger.debug("Checking if container {} is running".format(_required_container))

    if not _required_container in running_container_names:
        missing_containers.append(_required_container)

if len(missing_containers):
    reason = "Missing containers: {}".format(" ".join(missing_containers))
    logger.error(reason)
    sctask.signal_task_failure(flags.token, flags.taskid, reason=reason)
    sys.exit(1)

###############################################################################
# Iterate running containers and check if any of them has been running less
# than the duration indicated by the user
###############################################################################
for running_container_id, running_container_name in running_containers:
    logger.debug("Checking the uptime of container {} with ID {}".format(running_container_name, running_container_id))
    uptime_command = []
    uptime_command.append("docker")
    uptime_command.append("inspect")
    uptime_command.append(running_container_id)
    result = scutil.get_local_command_output(uptime_command)

    # Check exit code
    if result[0] != 0:
        reason = "Failed to get details of running container with ID {}".format(running_container_id)
        logger.error(reason)
        sctask.signal_task_failure(flags.token, flags.taskid, reason=reason)
        sys.exit(1)

    # Parse State.StartedAt field of the first element
    parser = json.loads(result[1])
    startedAtISO8601 = parser[0]['State']['StartedAt']
    logger.debug("StartedAt field {}".format(startedAtISO8601))

    uptime_in_minutes = scutil.minutes_since_ISO8601_date(startedAtISO8601)
    logger.debug("uptime_in_minutes = {}".format(uptime_in_minutes))

    if uptime_in_minutes < int(flags.uptime):
        reason = "Uptime of {} with ID {} is less than {} minute(s)".format(running_container_name, running_container_id, flags.uptime)
        logger.error(reason)
        sctask.signal_task_failure(flags.token, flags.taskid, reason=reason)
        sys.exit(1)

###############################################################################
# Everything seems to be fine
###############################################################################
sctask.signal_task_success(flags.token, flags.taskid)

sys.exit(0)
