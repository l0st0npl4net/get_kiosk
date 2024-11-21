#! /bin/bash

sudo chmod 777 -R /opt/sst-iiko/

terminals=(0 "PAX 300" off
        1 "KOZEN (TOUCH)" off)

ch=$(dialog --separate-output \
                --backtitle "УСТАНОВЩИК GET-KIOSK" \
                --title "Внедрение: Банковский Терминал" \
                --checklist "Выберите нужную модель(SPACE - выбрать):" \
                30 45 20 \
                  "${terminals[@]}" 2>&1 >/dev/tty)


for choice in $ch
do
      case $choice in
            0) PATH=app/sber/pax300/platforms;;
            1) PATH=app/sber/kozen/platforms;;
      esac
done

sudo cp -r ${PATH} /opt/sst-iiko/platforms

sudo cp app/connector/10-pinpad.rules /etc/udev/rules.d/10-pinpad.rules

sudo ln -s /dev/pinpad /opt/sst-iiko/platforms/ELF32_80386/ttyS99

sudo chmod 777 -R /opt/sst-iiko/platforms/
sudo /opt/sst-iiko/platforms/ELF32_80386/sb_pilot 7

sudo crudini --set  /etc/sst-iiko/settings.ini Terminal binfile sb_pilot
sudo crudini --set  /etc/sst-iiko/settings.ini Terminal delay 3000
sudo crudini --set  /etc/sst-iiko/settings.ini Terminal instantMode false
sudo crudini --set  /etc/sst-iiko/settings.ini Terminal path /opt/sst-iiko/platforms/ELF32_80386
sudo crudini --set  /etc/sst-iiko/settings.ini Terminal relative false
sudo crudini --set  /etc/sst-iiko/settings.ini Terminal type Sberbank
sudo sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" /etc/sst-iiko/settings.ini

echo "SBERBANK TERMINAL setup complete!"