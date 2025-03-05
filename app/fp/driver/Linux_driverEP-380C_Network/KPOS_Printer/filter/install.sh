#!/bin/sh
if [ $(getconf WORD_BIT) = '32' ] && [ $(getconf LONG_BIT) = '64' ] ; then
	cp ./64/rastertopos /usr/lib/cups/filter/
else
	cp ./32/rastertopos /usr/lib/cups/filter/
fi

sudo chmod a+x /usr/lib/cups/filter/rastertopos
sync

read -p "Printer IP: " PR_IP
read -p "Printer Port: " PR_PORT

sudo lpadmin -x REXOD

PR_URI=$(sudo lpinfo -v | grep direct)
sudo lpadmin -p REXOD -E -v socket://${PR_IP}:${PR_PORT} -P /tmp/get_kiosk-main/app/fp/driver/Linux_driverEP-380C_Network/KPOS_Printer/ppd/KPOS_80c.ppd

sudo crudini --set  /etc/sst-iiko/print_settings.ini Document Printer REXOD

