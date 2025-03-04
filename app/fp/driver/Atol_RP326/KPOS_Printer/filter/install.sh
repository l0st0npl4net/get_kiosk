#!/bin/sh
sudo cp rastertort58_80 /usr/lib/cups/filter/

sudo chmod a+x /usr/lib/cups/filter/rastertort58_80
sync

read -p "Printer IP: " PR_IP
read -p "Printer Port: " PR_PORT

sudo lpadmin -x RP326

sudo lpadmin -p RP326 -E -v socket://${PR_IP}:${PR_PORT} -P /tmp/get_kiosk-main/app/fp/driver/Sam4s_102c_Network/KPOS_Printer/filter/Printer80.ppd

sudo crudini --set  /etc/sst-iiko/print_settings.ini Document Printer RP326

