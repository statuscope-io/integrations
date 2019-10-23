# [check_docker_containers.py](check_docker_containers.py): Check certain containers' running state and uptime

To monitor your Docker deployment you should definitely check if certain containers are running. And yet this is not enough to see if they are restarting. An exception in the code may cause frequent restarts rendering your deployment unuseful.

Here is a high-level integration that lets you check if certain containers are running and that they are running for more than a configurable amount of minutes. It, of course, notifies Statuscope.io after. The beauty of it is that when you restart your system due to an update or test, task will be marked as successful only if your deployment keeps running for a certain amount of time.

To start, go create a heartbeat task on Statuscope and copy the Task token and Task ID before running this script.

Note that `--container` parameter can be repeated for as many containers as you want.

```
python3 check_docker_containers.py \
        --container=webserver \
        --container=databaseserver \
        --container=authserver \
        --uptime=15 \
        --token=<Task token> \
        --taskid=<Task ID>
```

To run it every 5 minutes, for example, add this to your crontab.

```
*/5 * * * * /usr/bin/python3 /opt/statuscopeio/docker/check_docker_containers.py --container=webserver --container=databaseserver --container=authserver --uptime=15 --token=439da120 --taskid=q72P7cmvBoR5mYojo
```
