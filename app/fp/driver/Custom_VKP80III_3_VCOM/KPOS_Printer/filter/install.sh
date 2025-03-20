#!/bin/sh
sudo apt-get install -y apparmor-utils
sudo aa-disable /usr/sbin/cupsd

sudo cp rastertovkp80iii_64bit /usr/lib/cups/filter/
sudo cp 20-printer.rules /etc/udev/rules.d/
sudo chmod a+x /usr/lib/cups/filter/rastertovkp80iii_64bit
sync

cat > /etc/rc.local <<EOF
#!/bin/sh
sudo chmod -R 666 /dev/ttyACM0
sudo chmod -R 666 /dev/ttyACM1
sudo chmod -R 666 /dev/vcom_printer
exit 0
EOF

sudo chmod +x /etc/rc.local

cat > /etc/systemd/system/rc-local.service <<EOF
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable rc-local
sudo systemctl restart rc-local

sudo lpadmin -x VKPIIII_VCOM -E -v serial:/dev/vcom_printer?baud=115200 -P /tmp/get_kiosk-main/app/fp/driver/Custom_VKP80II_2_VCOM/KPOS_Printer/filter/VKP80.ppd
sudo crudini --set  /etc/sst-iiko/print_settings.ini Document Printer VKPIII_VCOM