#! /bin/bash


sudo apt-get -y install x11vnc
sudo x11vnc -storepasswd "passw0rd" /etc/x11vnc.pass

sudo cat << EOL > /lib/systemd/system/x11vnc.service 
[Unit]
Description=Start x11vnc at startup.
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -noxdamage -shared -cursor none -dontdisconnect -many -noxfixes -rfbauth /etc/x11vnc.pass

[Install]
WantedBy=multi-user.target
EOL

sudo cat << EOL > /lib/systemd/system/xorg.service 
[Unit]
Description=Start xorg server at startup.
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/lib/xorg/Xorg

[Install]
WantedBy=multi-user.target
EOL

echo "X11VNC setup complete!"