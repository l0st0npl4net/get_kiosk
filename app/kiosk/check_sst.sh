#! /bin/sh

if ! package_exists sst-iiko ; then
    dpkg -l sst-iiko
    read -p "Package exists. Check for update? [y/n]: " YES
    
    if [ "$YES" = "Y" ] || [ "$YES" = "y" ]; then
        sudo apt-get update
        sudo apt-get -y install sst-iiko
    fi
else 
    sudo chmod +x app/kiosk/kiosk.sh
    sudo ./app/kiosk/kiosk.sh
fi