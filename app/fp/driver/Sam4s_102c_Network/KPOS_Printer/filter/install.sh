#!/bin/sh
sudo cp RasterToSPrinter /usr/lib/cups/filter/

sudo chmod a+x /usr/lib/cups/filter/RasterToSPrinter
sync

read -p "Printer IP: " PR_IP
read -p "Printer Port: " PR_PORT

sudo lpadmin -x SAM4S

sudo lpadmin -p SAM4S -E -v socket://${PR_IP}:${PR_PORT} -P /tmp/get_kiosk-main/app/fp/driver/Sam4s_102c_Network/KPOS_Printer/filter/SAM4s_gcube-102.ppd

sudo crudini --set  /etc/sst-iiko/print_settings.ini Document Printer SAM4S

