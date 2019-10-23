#! /usr/bin/env python
# coding=utf-8

import base64
import os
import paramiko

def get_remote_command_output(hostname, username, command):
    '''returns the output of a command run on a remote system'''

    try:
        client = paramiko.SSHClient()
        # Load host keys
        client.load_host_keys(os.path.expanduser('~/.ssh/known_hosts'))

        client.connect(hostname, username=username)
        stdin, stdout, stderr = client.exec_command(command)

        # Create a list from bulk output
        result = [line.strip() for line in stdout]

        # Close the connection and return
        client.close()
        return result

    except paramiko.ssh_exception.SSHException as ssh_exception:
        print(str(ssh_exception))
        return ''

def get_remote_command_exit_value(hostname, username, command):
    '''returns the exit value of a command run on a remote system'''

    try:
        client = paramiko.SSHClient()
        # Load host keys
        client.load_host_keys(os.path.expanduser('~/.ssh/known_hosts'))

        client.connect(hostname, username=username)
        stdin, stdout, stderr = client.exec_command(command)

        exit_value = stdout.channel.recv_exit_status()

        # Close the connection and return
        client.close()
        return exit_value

    except paramiko.ssh_exception.SSHException as ssh_exception:
        print(str(ssh_exception))
        return ''
