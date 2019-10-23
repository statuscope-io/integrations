#! /usr/bin/env python
# coding=utf-8

import argparse
import logging
import os
import sys

# Add internal library to paths
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '_lib'))

# Get a logger and set log level to INFO
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Import internal modules
from sccore import scssh, sctask

if __name__ != '__main__':
    logger.error('This script is to be run, not to be imported')
    sys.exit(0)

# Process command line arguments
parser = argparse.ArgumentParser()
parser.add_argument('--host', help="IP address/hostname of the system", required=True)
parser.add_argument('--service', help="Name of the service, e.g. cups", required=True)
parser.add_argument('--token', help="Statuscope.io user/task token", required=True)
parser.add_argument('--taskid', help="Statuscope.io task ID", required=True)
flags = parser.parse_args()

logger.info("Given flags are: {}".format(flags))

# Collect information on the service
is_enabled = scssh.get_remote_command_output(flags.host, 'root', 'systemctl is-enabled {}'.format(flags.service))[0]
is_running = scssh.get_remote_command_exit_value(flags.host, 'root', 'systemctl status {}'.format(flags.service)) == 0

logger.info("is_enabled: {}, is_running: {}".format(is_enabled, is_running))

# Do the actual check
message = ''
# If the message is not enabled at boot, assume it is failing
if is_enabled != 'enabled':
    message = "Service '%s' is NOT enabled." % (flags.service)
    logger.error(message)
    sctask.signal_task_failure(flags.token, flags.taskid, reason=message)
elif not is_running:
    message = "Service '%s' is enabled but NOT running." % (flags.service)
    logger.error(message)
    sctask.signal_task_failure(flags.token, flags.taskid, reason=message)
else:
    message = "Service '%s' is enabled and running." % (flags.service)
    logger.info(message)
    sctask.signal_task_success(flags.token, flags.taskid, reason=message)

