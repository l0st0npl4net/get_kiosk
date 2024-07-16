#! /bin/bash

sudo apt-get -y install cups
sudo cp app/fp/cupsd.conf /etc/cups/cupsd.conf
sudo chmod 755 -R /etc/cups/

DRV_VAR=$(dialog --stdout --fselect /tmp/get_kiosk/app/fp/driver 40 80)

# let i=0 # define counting variable
# W=() # define working array
# while read -r line; do # process file by file
#     let i=$i+1
#     W+=($i "$line")
# done < <( ls -1 /tmp/get_kiosk/app/fp/driver )
# DRV_VAR=$(dialog --title "List of printer drivers" --menu "Chose one" 24 80 17 "${W[@]}" 2>&1 >/dev/tty) # show dialog and store output

clear

sudo dpkg -i $DRV_VAR
sudo apt-get -y --fix-broken install 
sudo dpkg -i $DRV_VAR

sudo systemctl restart cups.service
sudo chmod 755 -R /etc/cups/
sudo usermod -a -G lpadmin proxyuser
sudo systemctl restart cups.service

PR_URI=$(sudo lpinfo -v | grep direct)
PR_DRV=$(sudo lpinfo -m | grep POS-80)
read -p "Printer Name: " PR_NAME

sudo lpadmin -p $PR_NAME -E -v ${PR_URI##* } -m ${PR_DRV%% *}
sudo lp -d REXOD /usr/share/cups/data/default-testpage.pdf

echo "Printer dealing with his first job..."
sleep 20s
sudo lpstat -W completed


echo "REXOD almost setup complete!"

