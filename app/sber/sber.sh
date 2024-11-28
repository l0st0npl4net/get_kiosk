#! /bin/bash

sudo chmod 777 -R /opt/sst-iiko/

# sudo cp -r app/sber/platforms /opt/sst-iiko/platforms
# sudo ln -s /dev/ttyACM0 /opt/sst-iiko/platforms/ELF32_80386/ttyS99

sudo chmod 777 -R /opt/sst-iiko/platforms/
sudo /opt/sst-iiko/platforms/ELF32_80386/sb_pilot 7

sudo crudini --set  /etc/sst-iiko/settings.ini Terminal binfile sb_pilot
sudo crudini --set  /etc/sst-iiko/settings.ini Terminal delay 3000
sudo crudini --set  /etc/sst-iiko/settings.ini Terminal instantMode false
sudo crudini --set  /etc/sst-iiko/settings.ini Terminal path /opt/sst-iiko/platforms/ELF32_80386
sudo crudini --set  /etc/sst-iiko/settings.ini Terminal relative false
sudo crudini --set  /etc/sst-iiko/settings.ini Terminal type Sberbank
sudo sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" /etc/sst-iiko/settings.ini

echo "SBERBANK TERMINAL setup complete!"