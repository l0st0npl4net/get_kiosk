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
      1 "Get-Kiosk" off
      2 "VPN" off
      3 "Terminal: INPASS DualConnector" off
	4 "Terminal: Sberbank" off
	5 "ATOL - fptr10_t" off
	6 "Pirit" off
	7 "Fiscal Printer REXOD" off)

choices=$(whiptail --separate-output \
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
            1) echo "app/kiosk/kiosk.sh" >> package.sh;; 
            2) echo "app/vpn/vpn.sh" >> package.sh;; 
            3) echo "app/connector/dualconnector.sh" >> package.sh;;
            4) echo "app/sber/sber.sh" >> package.sh;; 
            5) echo "sapp/atol/atol.sh" >> package.sh;; 
            6) echo "app/fito/fito.sh" >> package.sh;; 
            7) echo "app/fp/fp.sh" >> package.sh;; 
      esac
done


sudo chmod +x ./package.sh
./package.sh > $LOG 2>&1 | dialog --tailbox $LOG 80 180


clear