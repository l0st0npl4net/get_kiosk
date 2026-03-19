#! /bin/bash


source app/fiscal/fiscal.env
FISCAL=/

fiscal_list=(
        0 "Atol" off
        7 "SHTRIH-M" off)

ch=$(dialog --separate-output \
                --backtitle "УСТАНОВЩИК GET-KIOSK" \
                --title "Внедрение: ФР" \
                --checklist "Выберите ФР(SPACE - выбрать):" \
                30 45 20 \
                  "${fiscal_list[@]}" 2>&1 >/dev/tty)
clear

for choice in $ch
do
      case $choice in
            0) FISCAL=$ATOL;;
            1) FISCAL=$SHTRIh;;
      esac
done
sudo chmod +x $FISCAL
sudo $FISCAL