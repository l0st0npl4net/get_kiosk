#! /bin/bash

sudo apt install cups -y

sudo cp app/fp/cupsd.conf /etc/cups/cupsd.conf

sudo chmod 755 -R /etc/cups/

sudo dpkg -i app/fp/driver/*.deb

sudo apt -y --fix-broken install 

sudo dpkg -i app/fp/driver/*.deb

sudo systemctl restart cups.service

sudo chmod 755 -R /etc/cups/

sudo usermod -a -G lpadmin proxyuser

sudo systemctl restart cups.service

echo "Proccess complete!"

