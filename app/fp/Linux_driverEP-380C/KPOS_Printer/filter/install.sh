#!/bin/sh
if [ $(getconf WORD_BIT) = '32' ] && [ $(getconf LONG_BIT) = '64' ] ; then
	cp ./64/rastertopos /usr/lib/cups/filter/
else
	cp ./32/rastertopos /usr/lib/cups/filter/
fi

chmod a+x /usr/lib/cups/filter/rastertopos
sync


sudo lpadmin -x REXOD

PR_URI=$(sudo lpinfo -v | grep direct)
sudo lpadmin -p REXOD -E -v ${PR_URI##* } -P /tmp/get_kiosk-frank/app/fp/Linux_driverEP-380C/KPOS_Printer/ppd/KPOS_80c.ppd

