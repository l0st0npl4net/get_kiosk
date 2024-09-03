#! /bin/bash

sudo apt-get -y install cups
sudo cp app/fp/cupsd.conf /etc/cups/cupsd.conf
sudo cp app/fp/print_settings.ini /etc/sst-iiko/print_settings.ini
sudo cp app/fp/receipt.atdf /etc/sst-iiko/templates/receipt.atdf
sudo chmod 755 -R /etc/cups/

sudo dpkg -i app/fp/driver/printer-driver-pos_3.13.6_all.deb
sudo apt-get -y --fix-broken install 
sudo dpkg -i app/fp/driver/printer-driver-pos_3.13.6_all.deb

sudo systemctl restart cups.service
sudo chmod 755 -R /etc/cups/

cd app/fp/Linux_driverEP-380C/KPOS_Printer/filter 
sudo chmod +x ./install.sh 
sudo ./install.sh

sudo lp -d REXOD /usr/share/cups/data/default-testpage.pdf

echo "Printer dealing with his first job..."
sleep 20
sudo lpstat -W completed

echo "Printer setup complete!"
