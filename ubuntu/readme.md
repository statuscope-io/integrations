# [compare_pkg_configs.py](compare_pkg_configs.py): Compare production and staging configurations

A staging server is not only to test your applications, it is also to test your app's behavior against system updates. Comparing package configuration differences between https://www.statuscope.io/ and https://staging.statuscope.io/ was no different.

Here is a higher-level script that checks the contents of `/etc/os-release` and `dpkg --get-selections`.

Go create a heartbeat task on Statuscope and copy the Task token and Task ID before running this script.

```
python3 compare_pkg_configs.py \
        --production=<production IP> \
        --staging=<staging IP> \
        --token=<Task token> \
        --taskid=<Task ID>
```
