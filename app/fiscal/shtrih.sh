#! /bin/bash


RULE="KERNEL=="ttyACM[0-9]*", SUBSYSTEM=="tty", ATTRS{idVendor}=="1fc9", ATTRS{idProduct}=="0083", SYMLINK+="shtrih""
sudo echo $RULE >> /etc/udev/rules.d/shtrih.rules

sudo crudini --set  /etc/sst-iiko/settings.ini FP password 30 \
             --set  /etc/sst-iiko/settings.ini FP port /dev/shtrih \
             --set  /etc/sst-iiko/settings.ini FP summType Summ2 \
             --set  /etc/sst-iiko/settings.ini FP timeout 15000 \
             --set  /etc/sst-iiko/settings.ini FP type Shtrikh

sudo sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" /etc/sst-iiko/settings.ini

echo "SHTRIH-M setup complete!"