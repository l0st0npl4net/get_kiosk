#!/bin/sh
sudo cp RasterToSPrinter /usr/lib/cups/filter/

sudo chmod a+x /usr/lib/cups/filter/RasterToSPrinter
sync

sudo lpadmin -x SAM4S

PR_URI=$(sudo lpinfo -v | grep direct)
sudo lpadmin -p SAM4S -E -v ${PR_URI##* } -P /tmp/get_kiosk-main/app/fp/driver/Sam4s_102c/KPOS_Printer/filter/SAM4s_gcube-102.ppd

sudo crudini --set  /etc/sst-iiko/print_settings.ini Document Printer SAM4S