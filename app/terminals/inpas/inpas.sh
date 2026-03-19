#! /bin/bash


sudo apt-get -y install openjdk-21-jre openjdk-17-jre

sudo chmod 777 -R app/terminals/inpas/DC_Linux_Service
sudo chmod +x app/terminals/inpas/DC_Linux_Service/service.sh
sudo app/terminals/inpas/DC_Linux_Service/service.sh install

sudo crudini --set  /etc/sst-iiko/settings.ini Terminal terminalID \
             --set  /etc/sst-iiko/settings.ini Terminal type DualConnector
sudo sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" /etc/sst-iiko/settings.ini

sudo service dualconnector start

echo "DUALCONNECTOR setup complete!"