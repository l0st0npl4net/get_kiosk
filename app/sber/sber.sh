#! /bin/bash

sudo chmod 777 -R /opt/sst-iiko/

sudo cp -r app/sber/platforms /opt/sst-iiko/platforms
sudo ln -s /dev/ttyACM0 /opt/sst-iiko/platforms/ELF32_80386/ttyS99

sudo chmod 777 -R /opt/sst-iiko/platforms/
sudo /opt/sst-iiko/platforms/ELF32_80386/sb_pilot 7

echo "SBERBANK TERMINAL setup complete!"