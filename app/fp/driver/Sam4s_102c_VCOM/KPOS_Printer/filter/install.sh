#!/bin/sh
sudo apt-get install -y apparmor-utils
sudo aa-disable /usr/sbin/cupsd

sudo cp RasterToSPrinter /usr/lib/cups/filter/
sudo cp 20-printer.rules /etc/udev/rules.d/
sudo chmod a+x /usr/lib/cups/filter/RasterToSPrinter
sync

cat > /etc/rc.local <<EOF
#!/bin/sh
sudo chmod -R 666 /dev/ttyACM0
sudo chmod -R 666 /dev/ttyACM1
sudo chmod -R 666 /dev/vcom_printer
exit 0
EOF

sudo lpadmin -x SAM4S_VCOM
sudo lpadmin -p SAM4S_VCOM -E -v serial:/dev/vcom_printe?baud=115200 -P /tmp/get_kiosk-main/app/fp/driver/Sam4s_102c_VCOM/KPOS_Printer/filter/SAM4s_gcube-102.ppd
sudo crudini --set  /etc/sst-iiko/print_settings.ini Document Printer SAM4S_VCOM