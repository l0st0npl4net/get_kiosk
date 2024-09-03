#! /bin/sh

if ! package_exists sst-iiko ; then
    dpkg -l sst-iiko
    read -p "Install sst-iiko from scratch? [y/n]: " YES
    
    if [ "$YES" = "Y" ] || [ "$YES" = "y" ]; then
        sudo chmod +x app/kiosk/kiosk.sh
        sudo ./app/kiosk/kiosk.sh
    fi
else 
    sudo chmod +x app/kiosk/kiosk.sh
    sudo ./app/kiosk/kiosk.sh
fi