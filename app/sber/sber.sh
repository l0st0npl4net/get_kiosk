#! /bin/bash

sudo chmod 777 -R /opt/sst-iiko/

sudo cp app/sber/platforms /opt/sst-iiko/platforms

sudo cp app/connector/10-pinpad.rules /etc/udev/rules.d/10-pinpad.rules

sudo ln -s /dev/pinpad /opt/sst-iiko/platforms/ELF32_80386/ttyS99

sudo chmod 777 -R /opt/sst-iiko/platforms/

sudo /opt/sst-iiko/platforms/ELF32_80386/sb_pilot 7

echo "SBERBANK TERMINAL setup complete!"