#! /bin/bash

sudo apt-get -y install cups
sudo cp app/fp/cupsd.conf /etc/cups/cupsd.conf
sudo cp app/fp/print_settings.ini /etc/sst-iiko/print_settings.ini
sudo mkdir /etc/sst-iiko/templates
sudo cp app/fp/receipt.atdf /etc/sst-iiko/templates
sudo chmod 755 -R /etc/cups/

# DRV_VAR=$(dialog --stdout --fselect /tmp/get_kiosk-main/app/fp/driver/ 40 80)
# clear 

# sudo dpkg -i $DRV_VAR
# sudo apt-get -y --fix-broken install 
# sudo dpkg -i $DRV_VAR

# sudo systemctl restart cups.service
sudo chmod 755 -R /etc/cups/

printers=(0 "REXOD" off
        1 "SAM4S 102c" off)

ch=$(dialog --separate-output \
                --backtitle "УСТАНОВЩИК GET-KIOSK" \
                --title "Внедрение: Чековый принтер" \
                --checklist "Выберите нужную модель(SPACE - выбрать):" \
                30 45 20 \
                  "${printers[@]}" 2>&1 >/dev/tty)
clear
PH=/

for choice in $ch
do
      case $choice in
            0) PH="Linux_driverEP-380C";;
            1) PH="Sam4s_Calisto_102c";;
      esac
done
# sudo usermod -a -G lpadmin proxyuser
# sudo systemctl restart cups.service

# sudo lpadmin -x REXOD

# PR_URI=$(sudo lpinfo -v | grep "direct usb")
# PR_DRV=$(sudo lpinfo -m | grep POS-80)

# read -p "Printer Name: " PR_NAME

# sudo lpadmin -p $PR_NAME -E -v ${PR_URI##* } -m ${PR_DRV%% *}
# sudo lp -d $PR_NAME /usr/share/cups/data/default-testpage.pdf

# echo "Printer dealing with his first job..."
# sleep 20
# sudo lpstat -W completed

cd app/fp/driver/"$PH"/KPOS_Printer/filter && sudo chmod +x ./install.sh && sudo ./install.sh

echo "Printer almost setup complete!"

