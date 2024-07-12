#! /bin/bash

#Установка
sudo apt install x11vnc -y

sudo cp app/vnc/x11vnc.pass /etc/x11vnc.pass

sudo cp app/vnc/x11vnc.service /lib/systemd/system/x11vnc.service

sudo systemctl enable x11vnc.service

sudo cp app/vnc/xorg.service /lib/systemd/system/xorg.service

sudo systemctl enable xorg.service


#Запуск
sudo systemctl start xsst-iiko

sudo systemctl enable xsst-iiko
sudo systemctl disable sst-iiko

sudo systemctl start xorg.service
sudo systemctl start x11vnc

echo "Proccess complete!"