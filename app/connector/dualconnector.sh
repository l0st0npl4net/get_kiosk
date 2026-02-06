#! /bin/bash


sudo apt-get -y install openjdk-21-jre
sudo apt-get -y install openjdk-17-jre

sudo cp -r app/connector/DC_Linux_Service /tmp

sudo chmod 777 -R /tmp/DC_Linux_Service

sudo chmod +x /tmp/DC_Linux_Service/service.sh

sudo /tmp/DC_Linux_Service/service.sh install

sudo cp -r /tmp/DC_Linux_Service/Documents /home/proxyuser/DC_Linux_Service/Documents

terminals=(0 "PAX 300" off
        1 "VERIFONE" off
        2 "P8 Unitoid" off
        3 "PAX CMF8" off)

ch=$(dialog --separate-output \
                --backtitle "УСТАНОВЩИК GET-KIOSK" \
                --title "Внедрение: Банковский Терминал" \
                --checklist "Выберите нужную модель(SPACE - выбрать):" \
                30 45 20 \
                  "${terminals[@]}" 2>&1 >/dev/tty)

PH=/

for choice in $ch
do
      case $choice in
            0) PH="pax300";;
            1) PH="verifone";;
            2) PH="p8_unitoid";;
            3) PH="pax_cmf8";;
      esac
done


sudo cp app/connector/"$PH"/10-pinpad.rules /etc/udev/rules.d/10-pinpad.rules

sudo crudini --set  /etc/sst-iiko/settings.ini Terminal terminalID
sudo crudini --set  /etc/sst-iiko/settings.ini Terminal type DualConnector
sudo sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" /etc/sst-iiko/settings.ini

sudo service dualconnector start

echo "DUALCONNECTOR setup complete!"