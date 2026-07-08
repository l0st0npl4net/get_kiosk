#! /bin/bash

sudo apt-get update && sudo apt-get install -y x11-xserver-utils

sudo bash -c 'cat > /lib/systemd/system/xsetoff.service <<EOF
[Unit]
Description=Disable DPMS and screensaver
After=graphical.target gdm.service
Wants=gdm.service
[Service]
Type=simple
User=proxyuser
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/proxyuser/.Xauthority
ExecStartPre=/bin/sleep 20
ExecStart=/opt/noblank.sh
[Install]
WantedBy=graphical.target
EOF'

sudo bash -c 'cat > /opt/noblank.sh <<EOF
#!/bin/bash
sleep 50
sudo systemctl start xsst-iiko
sleep 10
export DISPLAY=:0
export XAUTHORITY=/home/proxyuser/.Xauthority
xset s off
xset s noblank
xset -dpms
EOF'

sudo su -c 'cat <<EOF> /usr/share/X11/xorg.conf.d/99-display.conf
Section "ServerFlags"
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
EndSection

Section "Monitor"
    Identifier "eDP-1"
    Option "DPMS" "false"
EndSection

Section "ServerLayout"
    Identifier "ServerLayout0"
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
EndSection
EOF'

sudo chmod 777 -R /opt/
sudo systemctl enable xsetoff
sudo systemctl start xsetoff

sudo systemctl daemon-reload
