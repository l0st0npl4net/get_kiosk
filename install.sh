#! /bin/bash

sudo apt install dialog
sudo apt install whiptail
HEIGHT=30
WIDTH=45
CHOICE_HEIGHT=20
BACKTITLE="УСТАНОВЩИК GET-KIOSK"
TITLE="Внедрение: Установщик Киоска"
MENU="Выберите нужные компоненты(SPACE - выбрать):"

OPTIONS=(0 "Proxyuser" off
      1 "Get-Kiosk" off
      2 "VPN" off
      3 "Terminal: INPASS DualConnector" off
	4 "Terminal: Sberbank" off
	5 "ATOL - fptr10_t" off
	6 "Pirit" off
	7 "Fiscal Printer" off)

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
            0) sh app/proxyuser.sh;;
            1) sh app/kiosk/kiosk.sh;;
            2) sh app//vpn/vpn.sh ;;
            3) sh app/connector/dualconnector.sh;;
            4) sh app/sber/sber.sh;;
            5) sudo apt install fptr10-test-util;;
            6) sh app/fito/fito.sh;;
            7) sh app/fp/fp.sh;;
      esac
done
