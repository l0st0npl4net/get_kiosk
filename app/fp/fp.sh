#! /bin/bash

sudo apt-get -y install cups
sudo cp app/fp/cupsd.conf /etc/cups/cupsd.conf
sudo chmod 755 -R /etc/cups/
sudo dpkg -i app/fp/driver/*.deb
sudo apt-get -y --fix-broken install 
sudo dpkg -i app/fp/driver/*.deb

sudo systemctl restart cups.service
sudo chmod 755 -R /etc/cups/
sudo usermod -a -G lpadmin proxyuser
sudo systemctl restart cups.service

PR_URI=$(sudo lpinfo -v | grep direct)
PR_DRV=$(sudo lpinfo -m | grep POS-80)
read -p "Printer Name: " PR_NAME

sudo lpadmin -p $PR_NAME -E -v ${PR_URI##* } -m ${PR_DRV%% *}

echo "REXOD almost setup complete!"

