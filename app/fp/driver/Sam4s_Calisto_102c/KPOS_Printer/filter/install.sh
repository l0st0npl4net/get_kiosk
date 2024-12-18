#!/bin/sh
if [ $(getconf WORD_BIT) = '32' ] && [ $(getconf LONG_BIT) = '64' ] ; then
	cp ./64/RasterToSPrinter /usr/lib/cups/filter/
else
	cp ./32/RasterToSPrinter /usr/lib/cups/filter/
fi

sudo chmod a+x /usr/lib/cups/filter/RasterToSPrinter
sync


sudo lpadmin -x SAM4S

PR_URI=$(sudo lpinfo -v | grep direct)
sudo lpadmin -p SAM4S -E -v ${PR_URI##* } -P /tmp/get_kiosk-main/app/fp/driver/Sam4s_Calisto_102c/KPOS_Printer/ppd/SAM4s_gcube-102.ppd

