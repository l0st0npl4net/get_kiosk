#! /bin/bash

HEIGHT=30
WIDTH=45
CHOICE_HEIGHT=20
BACKTITLE="УСТАНОВЩИК GET-KIOSK"
TITLE="Внедрение: Установщик Киоска"
MENU="Выберите нужные компоненты(SPACE - выбрать):"
LOG=logs/install.log
DIR=/tmp/get_kiosk-main
LOG_DIR=/tmp/get_kiosk-main/logs


cd $DIR
sudo rm ./package.sh
echo "#! /bin/bash" >> package.sh

if [ -d "$LOG_DIR" ];
then
      echo "Get Kios Installation Logs" > $LOG
else
      mkdir $LOG_DIR && echo "Get Kios Installation Logs" > $LOG
fi

dialog --textbox README.md 50 120

OPTIONS=(
      0 "Proxyuser" off
      1 "OpenVPN" off 
      2 "Change Hostname" off
      3 "Get-Kiosk" off
      4 "Terminal: INPASS DualConnector" off
	5 "Terminal: Sberbank" off
      6 "Terminal: UCS" off
	7 "ATOL - fptr10_t" off
	8 "Shtrikh-M" off
	9 "Fiscal Printer Install" off
      10 "X11VNC install" off
      11 "X11VNC enable" off
      12 "X11VNC disable" off
      13 "Zabbix" off)

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
            2) echo "app/hostname.sh" >> package.sh;; 
            3) echo "app/kiosk/check_sst.sh" >> package.sh;;
            4) echo "app/connector/dualconnector.sh" >> package.sh;;
            5) echo "app/sber/sber.sh" >> package.sh;;
            6) echo "app/ucs/ucs.sh" >> package.sh;; 
            7) echo "app/atol/atol.sh" >> package.sh;; 
            8) echo "app/shtrih-m/shtrih.sh" >> package.sh;;
            9) echo "app/fp/fp.sh" >> package.sh;; 
            10) echo "app/vnc/vnc_setup.sh" >> package.sh;; 
            11) echo "app/vnc/vnc_start.sh" >> package.sh;;
            12) echo "app/vnc/vnc_stop.sh" >> package.sh;; 
            13) echo "app/zabbix/zabbix.sh" >> package.sh;; 
            
      esac
done


sudo chmod +x ./package.sh
sudo ./package.sh | tee $LOG