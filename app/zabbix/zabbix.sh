#! /bin/sh

sudo apt-get update && sudo apt-get -y install zabbix-agent curl
sudo apt-get -y install coreutils

read -p "Kiosk name for Zabbix: " kiosk_name

sudo sed -i "/Hostname/s/=.*/=$kiosk_name/" app/zabbix/zabbix_agentd.conf

sudo cp app/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf 

sudo mkdir /etc/zabbix/scripts && sudo touch /etc/zabbix/scripts/status-check.sh && echo "curl -s -o /dev/null -w "%{http_code}" http://localhost:10000" | sudo tee -a /etc/zabbix/scripts/status-check.sh
sudo chown proxyuser:proxyuser /etc/zabbix/zabbix_agentd.conf.d 
sudo chown proxyuser:proxyuser /etc/zabbix/scripts

echo "curl -s http://localhost:10000 | grep Network" | sudo tee -a /etc/zabbix/scripts/hardware-status-net.sh
echo "curl -s http://localhost:10000 | grep Print" | sudo tee -a /etc/zabbix/scripts/hardware-status-print.sh
echo "curl -s http://localhost:10000 | grep Terminal" | sudo tee -a /etc/zabbix/scripts/hardware-status-terminal.sh
echo "UserParameter=status-check,/etc/zabbix/scripts/status-check.sh" | sudo tee -a /etc/zabbix/zabbix_agentd.conf.d/staus-check.conf
echo "UserParameter=hardware-status-net,/etc/zabbix/scripts/hardware-status-net.sh" | sudo tee -a /etc/zabbix/zabbix_agentd.conf.d/staus-check.conf
echo "UserParameter=hardware-status-print,/etc/zabbix/scripts/hardware-status-print.sh" | sudo tee -a /etc/zabbix/zabbix_agentd.conf.d/staus-check.conf
echo "UserParameter=hardware-status-terminal,/etc/zabbix/scripts/hardware-status-terminal.sh" | sudo tee -a /etc/zabbix/zabbix_agentd.conf.d/staus-check.conf

sudo service zabbix-agent restart
