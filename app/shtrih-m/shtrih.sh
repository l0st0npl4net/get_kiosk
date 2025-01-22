#! /bin/bash
sudo cp app/shtrih-m/printer.rules /etc/udev/rules.d/printer.rules

sudo crudini --set  /etc/sst-iiko/settings.ini FP password 30
sudo crudini --set  /etc/sst-iiko/settings.ini FP port /dev/printer
sudo crudini --set  /etc/sst-iiko/settings.ini FP summType Summ2
sudo crudini --set  /etc/sst-iiko/settings.ini FP timeout 15000
sudo crudini --set  /etc/sst-iiko/settings.ini FP type Shtrikh

sudo sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" /etc/sst-iiko/settings.ini

echo "SHTRIH-M setup complete!"