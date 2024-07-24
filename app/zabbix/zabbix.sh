#! /bin/sh

sudo apt-get update && sudo apt-get -y install zabbix-agent curl
sudo apt-get -y install coreutils

sudo nano /etc/zabbix/zabbix_agentd.conf

sudo mkdir /etc/zabbix/scripts && sudo touch /etc/zabbix/scripts/status-check.sh && echo "curl -s -o /dev/null -w "%{http_code}" http://localhost:10000" | sudo tee -a /etc/zabbix/scripts/status-check.sh