#! /bin/bash


HEIGHT=30
WIDTH=45
CHOICE_HEIGHT=20
BACKTITLE="УСТАНОВЩИК GET-KIOSK"
TITLE="Внедрение: Установщик Киоска"
MENU="Выберите нужные компоненты(SPACE - выбрать):"
LOG=kiosk_install.log
DIR=/tmp/get_kiosk-main
LOG_DIR=/tmp/get_kiosk-main/logs


cd $DIR
sudo rm ./package.sh
echo "#! /bin/bash" >> package.sh

if [ -d "$LOG_DIR" ];
then
      echo "Get Kios Installation Logs" > $LOG
else
      mkdir $LOG_DIR && echo "Get Kiosk Installation Logs" > $LOG
fi

dialog --textbox README.md 100 120

OPTIONS=(
      0 "Set proxyuser" off
      1 "Setup VPN" off 
      2 "Change Hostname" off
      3 "Get-Kiosk setup" off
      4 "Screensaver disable" off
      5 "Terminal setup" off
	6 "Fiscal setup" off
	7 "Printer setup" off
      8 "VNC: install" off
      9 "VNC: enable" off
      10 "VNC: disable" off
      11 "Zabbix" off)

choices=$(dialog --separate-output \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --checklist "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                  "${OPTIONS[@]}" 2>&1 >/dev/tty)


for choice in $choices
do
      case $choice in
            0) echo "app/proxyuser.sh" >> package.sh;; 
            1) echo "app/vpn.sh" >> package.sh;; 
            2) echo "app/hostname.sh" >> package.sh;; 
            3) echo "app/sst/check.sh" >> package.sh;;
            4) echo "app/screensaver.sh" >> package.sh;;
            5) echo "app/terminals/setup.sh" >> package.sh;;
            6) echo "app/fiscal/setup.sh" >> package.sh;; 
            7) echo "app/printer/setup.sh" >> package.sh;; 
            8) echo "app/vnc/setup.sh" >> package.sh;; 
            9) echo "app/vnc/enable.sh" >> package.sh;;
            10) echo "app/vnc/disable.sh" >> package.sh;; 
            11) echo "app/zabbix/zabbix.sh" >> package.sh;; 
            
      esac
done


sudo chmod +x ./package.sh
sudo ./package.sh | tee $LOG