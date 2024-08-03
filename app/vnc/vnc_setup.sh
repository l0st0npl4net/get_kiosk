#! /bin/bash

#Установка
sudo apt-get -y install x11vnc

sudo cp app/vnc/x11vnc.pass /etc/x11vnc.pass
sudo cp app/vnc/x11vnc.service /lib/systemd/system/x11vnc.service
sudo cp app/vnc/xorg.service /lib/systemd/system/xorg.service

echo "X11VNC setup complete!"