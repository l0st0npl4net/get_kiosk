#!/bin/sh

ln -s /home/reg/arcus/ipservice/arcusip_suse /etc/init.d/arcusip
chmod -v +x /etc/init.d/arcusip
#update-rc.d arcusip defaults
chkconfig -add arcusip

