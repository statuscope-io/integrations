#! /usr/bin/env python
# coding=utf-8

import argparse
import logging
import sys

# Add internal library to paths
sys.path.append('../_lib')
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
parser.add_argument('--production', help="IP address/hostname of the production system", required=True)
parser.add_argument('--staging', help="IP address/hostname of the staging system", required=True)
parser.add_argument('--token', help="Statuscope.io user/task token", required=True)
parser.add_argument('--taskid', help="Statuscope.io task ID", required=True)
flags = parser.parse_args()

logger.info("Given flags are: {}".format(flags))

# Collect OS versions
os_rel_prod = scssh.get_remote_command_output(flags.production, 'root', 'cat /etc/os-release')
os_rel_staging = scssh.get_remote_command_output(flags.staging, 'root', 'cat /etc/os-release')

# Compare OS versions
try:
    # Parse /etc/os-release content into a dictionary
    os_ver_prod= dict(v.split('=') for v in os_rel_prod)['PRETTY_NAME']
    os_ver_staging = dict(v.split('=') for v in os_rel_staging)['PRETTY_NAME']

except Exception as e:
    logger.error("Cannot get OS versions: {}".format(str(e)))

if os_rel_prod != os_rel_staging:
    message = "OS mismatch: production is %s while staging is %s"
    logger.error(message % (os_ver_prod, os_ver_staging))
    sctask.signal_task_failure(flags.token, flags.taskid, reason=message)
else:
    logger.info("OS match: production and staging have the same OS")
    # Do not signal success yet, we'll compare packages

# Collect installed packages
pkgs_prod = scssh.get_remote_command_output(flags.production, 'root', 'dpkg --get-selections | grep -v deinstall | sort')
pkgs_staging = scssh.get_remote_command_output(flags.staging, 'root', 'dpkg --get-selections | grep -v deinstall | sort')

# Post-process the result to find package names
differences = list(set(pkgs_prod) - set(pkgs_staging))
differences = [d.split()[0] for d in differences]
logger.debug(differences)

if len(differences):
    logger.error("There are %d package differences between production and staging" % (len(differences)))
    logger.info("Different packages are {}".format(' '.join(differences)))
    sctask.signal_task_failure(flags.token, flags.taskid, reason="{} difference(s) found".format(len(differences)))
else:
    logger.info("Production and staging have the same package configuration")
    sctask.signal_task_success(flags.token, flags.taskid)
