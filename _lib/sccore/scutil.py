#! /usr/bin/env python
# coding=utf-8

import platform
import os

def is_linux():
    '''sends True if OS is Linux, False otherwise'''
    return platform.system() == 'Linux'

def is_windows():
    '''sends True if OS is Windows, False otherwise'''
    return platform.system() == 'Windows'

def get_user_home_path():
    return os.path.expanduser("~")
