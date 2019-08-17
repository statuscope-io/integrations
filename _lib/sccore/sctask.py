#! /usr/bin/env python
# coding=utf-8

import requests
import simplejson
import sys

# Get a logger and set log level to INFO
import logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def signal_task_status(token, taskid, status, reason):
    '''sends an update to a task on Statuscope.io'''

    if not status.upper() in [ 'OK', 'KO' ]:
        logger.error('Task status should be OK or KO: {} is invalid'.format(status))
        return False

    if status.upper() == 'KO' and not reason:
        logger.error('Reason cannot be empty while status is KO')

    # Prepare headers and data for the request
    headers = {'Content-Type':'application/json'}
    data = {'token':token, 'status':status}

    if reason:
        data['reason'] = reason

    try:
        r = requests.post('https://api.statuscope.io/tasks/' + taskid, data=simplejson.dumps(data), headers=headers)

        # Print only first 100 characters, since successful responses are shorter
        logger.debug("Server returned: {}".format(r.text[:100]))

        # Access response fields and values
        if r.json()['result'] == 'OK':
            logger.info('Success in server response')
            return True

        else:
            logger.error('Failure in server response')
            return False

    except requests.exceptions.ConnectionError as ConnErr:
        logger.error("Cannot connect to server")
        return False

    except simplejson.scanner.JSONDecodeError as DecodeErr:
        print("Cannot decode server response")
        return False

def signal_task_success(token, taskid, reason=None):
    '''sends an OK signal to a task on Statuscope.io'''

    return signal_task_status(token, taskid, 'OK', reason)

def signal_task_failure(token, taskid, reason):
    '''sends an KO signal to a task on Statuscope.io'''

    return signal_task_status(token, taskid, 'KO', reason)
