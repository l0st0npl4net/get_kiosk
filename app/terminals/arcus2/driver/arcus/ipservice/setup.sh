#!/bin/sh

os="";

grep "debian" /etc/issue -i -q
if [ $? = '0' ]; then
	echo "Seting up Debian service"
	/home/reg/arcus/ipservice/setup_debian.sh
	exit
fi

grep "suse" /etc/issue -i -q
if [ $? = '0' ]; then
	echo "Seting up SUSE service"
	/home/reg/arcus/ipservice/setup_suse.sh
	exit
fi


ln -s /home/reg/arcus/ipservice/arcusip /etc/init.d/arcusip
chmod -v +x /etc/init.d/arcusip
chkconfig --add arcusip
