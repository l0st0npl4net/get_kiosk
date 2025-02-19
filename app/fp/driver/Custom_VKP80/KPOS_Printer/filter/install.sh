#!/bin/sh
sudo cp rastertovkp80 /usr/lib/cups/filter/

sudo chmod a+x /usr/lib/cups/filter/rastertovkp80
sync

sudo lpadmin -x VKP80

PR_URI=$(sudo lpinfo -v | grep direct)
sudo lpadmin -p VKP80 -E -v ${PR_URI##* } -P /tmp/get_kiosk-main/app/fp/driver/Custom_VKP80/KPOS_Printer/filter/VKP80.ppd

sudo crudini --set  /etc/sst-iiko/print_settings.ini Document Printer VKP80

