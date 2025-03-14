# lmt-host-setup
This is a repository I created that will configure monit for specific types of server deployments.
* Choose what Ubuntu default monit configuration to setup
* Script for alerting that uses postmark and gotify.

## monit-setup
This script will configure monit for specific types of server deployments.
* Choose what Ubuntu default monit configuration to setup
* Script for alerting that uses postmark and gotify.
* smartmontools
* mdadm

## slack
* Sent test slack alert via shell script

# Notes
## gotify
Sending alerts to gotify server
```
curl -X POST "http://gotify.domain.com/message?token=token" -F "title=Test" -F "message=Test"
```