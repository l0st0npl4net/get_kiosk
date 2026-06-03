#! /bin/bash


source app/terminals/terminal.env
TERMINAL=/
INTEGRATION=/


terminal_list=(
        0 "Sberbank" off
        1 "Inpas" off
        2 "Arcus" off)

ch=$(dialog --separate-output \
                --backtitle "УСТАНОВЩИК GET-KIOSK" \
                --title "Внедрение: Интеграция" \
                --checklist "Выберите интеграцию(SPACE - выбрать):" \
                30 45 20 \
                  "${terminal_list[@]}" 2>&1 >/dev/tty)
clear

for choice in $ch
do
      case $choice in
            0) INTEGRATION=$SBERBANK;;
            1) INTEGRATION=$INPAS;;
            2) INTEGRATION=$ARCUS;;
      esac
done


#Выбор терминала 
terminalList=(0 "P8 Unitoid" off
        1 "KOZEN (TOUCH)" off
        2 "VERIFONE" off
        3 "Ingenica IPP320 (Sagem)" off
        4 "PAX 300" off
        5 "PAX SP30" off
        6 "PAX IM20" off
        7 "PAX CMF8" off)

ch=$(dialog --separate-output \
                --backtitle "УСТАНОВЩИК GET-KIOSK" \
                --title "Внедрение: Банковский Терминал" \
                --checklist "Выберите нужную модель(SPACE - выбрать):" \
                30 45 20 \
                  "${terminalList[@]}" 2>&1 >/dev/tty)
clear

for choice in $ch
do
      case $choice in
            0) TERMINAL=$P8UNITOID;;
            1) TERMINAL=$KOZEN;;
            2) TERMINAL=$VERIFONE;;
            3) TERMINAL=$IPP320SAGEM;;
            4) TERMINAL=$PAX300;;
            5) TERMINAL=$PAXSP30;;
            6) TERMINAL=$PAXIM20;;
            7) TERMINAL=$PAXCMF8;;
      esac
done


RULE=$BASE$TERMINAl
sudo echo $RULE >> /etc/udev/rules.d/10-pinpad.rules


sudo chmod +x $INTEGRATION
sudo $INTEGRATION