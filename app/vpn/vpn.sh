#! /bin/bash 

#Устанавливаем и настраиваем ВПН
sudo apt-get -y install openvpn
sudo cp app/vpn/openvpn /etc/default/openvpn
sudo systemctl enable openvpn.service

read -p "OpenVPN configue URL: " VPN_URL
wget $VPN_URL -P app/vpn

if [ -e app/vpn/*.ovpn ]
then
    sudo cp app/vpn/*.ovpn /etc/openvpn/client.conf
    echo "OpenVPN setup complete (reboot required)"
else 
    echo "OVPN file not exist!"
fi