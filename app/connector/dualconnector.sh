#! /bin/sh


sudo apt-get -y install openjdk-17-jre

sudo cp -r app/connector/DC_Linux_Service /tmp

sudo chmod 777 -R /tmp/DC_Linux_Service

sudo chmod +x /tmp/DC_Linux_Service/service.sh

sudo /tmp/DC_Linux_Service/service.sh install

sudo cp app/connector/DC_Linux_Service/Documents cp /home/proxyuser/DC_Linux_Service/Documents
sudo cp app/connector/10-pinpad.rules /etc/udev/rules.d/10-pinpad.rules

sudo service dualconnector start

echo "DUALCONNECTOR setup complete!"