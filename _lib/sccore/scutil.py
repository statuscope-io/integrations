#! /usr/bin/env python
# coding=utf-8

import subprocess
import platform
import os
import sys
import dateutil.parser
import datetime
import pytz

def is_linux():
    '''sends True if OS is Linux, False otherwise'''
    return platform.system() == 'Linux'

def is_windows():
    '''sends True if OS is Windows, False otherwise'''
    return platform.system() == 'Windows'

def get_user_home_path():
    return os.path.expanduser("~")

def get_local_command_output(command):
    '''returns the output and exit value of a command run on local system'''

    try:
        process = subprocess.Popen(command, stderr=subprocess.PIPE, stdout=subprocess.PIPE, shell=False)
        process.wait()
        out, err = process.communicate()

        return process.returncode, out.decode(), err.decode()

    except Exception as e:
        print(str(e))
        return ''

def minutes_since_ISO8601_date(iso8601_date):
    now = datetime.datetime.utcnow().replace(tzinfo=datetime.timezone.utc)
    past = dateutil.parser.parse(iso8601_date)

    return int(((now - past).total_seconds()) / 60)
