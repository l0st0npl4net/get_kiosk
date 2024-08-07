#! /bin/bash

HEIGHT=30
WIDTH=45
CHOICE_HEIGHT=20
BACKTITLE="УСТАНОВЩИК GET-KIOSK"
TITLE="Внедрение: Установщик Киоска"
MENU="Выберите нужные компоненты(SPACE - выбрать):"
LOG=logs/install.log
DIR=/tmp/get_kiosk
LOG_DIR=/tmp/get_kiosk/logs


cd $DIR
sudo rm ./package.sh

if [ -d "$LOG_DIR" ];
then
      echo "Get Kios Installation Logs" > $LOG
else
      mkdir $LOG_DIR && echo "Get Kios Installation Logs" > $LOG
fi

dialog --textbox README.md 40 100

OPTIONS=(0 "Proxyuser" off
      1 "OpenVPN" off
      2 "Get-Kiosk" off
      3 "Terminal: INPASS DualConnector" off
	4 "Terminal: Sberbank" off
      5 "Terminal: UCS" off
	6 "ATOL - fptr10_t" off
	7 "Pirit" off
	8 "Fiscal Printer Install" off
      9 "X11VNC install" off
      10 "X11VNC start" off
      11 "Zabbix" off)

choices=$(dialog --separate-output \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --checklist "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                  "${OPTIONS[@]}" 2>&1 >/dev/tty)
clear


for choice in $choices
do
      case $choice in
            0) echo "app/proxyuser.sh" >> package.sh;; 
            1) echo "app/vpn/vpn.sh" >> package.sh;; 
            2) echo "app/kiosk/kiosk.sh" >> package.sh;;
            3) echo "app/connector/dualconnector.sh" >> package.sh;;
            4) echo "app/sber/sber.sh" >> package.sh;;
            5) echo "app/ucs/ucs.sh" >> package.sh;; 
            6) echo "app/atol/atol.sh" >> package.sh;; 
            7) echo "app/fito/fito.sh" >> package.sh;; 
            8) echo "app/fp/fp.sh" >> package.sh;; 
            9) echo "app/vnc/vnc_setup.sh" >> package.sh;; 
            10) echo "app/vnc/vnc_start.sh" >> package.sh;; 
            11) echo "app/zabbix/zabbix.sh" >> package.sh;; 
      esac
done


sudo chmod +x ./package.sh
./package.sh > $LOG
