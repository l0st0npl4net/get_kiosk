#! /bin/bash


sudo cp -r app/terminals/sber/"$PH"/platforms /opt/sst-iiko/

sudo chmod 777 -R /opt/sst-iiko/

sudo rm /opt/sst-iiko/platforms/ELF32_80386/ttyS99
sudo ln -s /dev/pinpad /opt/sst-iiko/platforms/ELF32_80386/ttyS99

sudo /opt/sst-iiko/platforms/ELF32_80386/sb_pilot 7

sudo crudini --set  /etc/sst-iiko/settings.ini Terminal binfile sb_pilot \
             --set  /etc/sst-iiko/settings.ini Terminal delay 3000 \
             --set  /etc/sst-iiko/settings.ini Terminal instantMode false \
             --set  /etc/sst-iiko/settings.ini Terminal path /opt/sst-iiko/platforms/ELF32_80386 \
             --set  /etc/sst-iiko/settings.ini Terminal relative false \
             --set  /etc/sst-iiko/settings.ini Terminal type Sberbank
sudo sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" /etc/sst-iiko/settings.ini

echo "SBERBANK TERMINAL setup complete!"