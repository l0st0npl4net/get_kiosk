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
            0) sh app/proxyuser.sh > logs/proxyuser.log 2>&1 | dialog --tailbox logs/proxyuser.log 100 200;;
            1) sh app/kiosk/kiosk.sh > logs/kiosk.log 2>&1 | dialog --tailbox logs/kiosk.log 100 200;;
            2) sh app//vpn/vpn.sh > logs/vpn.log 2>&1 | dialog --tailbox logs/vpn.log 100 200;;
            3) sh app/connector/dualconnector.sh > logs/dualconnector.log 2>&1 | dialog --tailbox logs/dialconnector.log 100 200;;
            4) sh app/sber/sber.sh > logs/sber.log 2>&1 | dialog --tailbox logs/sber.log 100 200;;
            5) sudo apt install fptr10-test-util > logs/atol.log 2>&1 | dialog --tailbox logs/atol.log 100 200;;
            6) sh app/fito/fito.sh > logs/pirit.log 2>&1 | dialog --tailbox logs/pirit.log 100 200;;
            7) sh app/fp/fp.sh > logs/printer.log 2>&1 | dialog --tailbox logs/printer.log 100 200;;
      esac
done
