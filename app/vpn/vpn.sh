#! /bin/bash 

#Устанавливаем и настраиваем ВПН
sudo apt install openvpn -y

sudo cp app/vpn/openvpn /etc/default/openvpn

sudo systemctl enable openvpn.service

read -p "VPN file download link: " vpnvar 

wget $vpnvar -P app/vpn

if [ -e vpn/*.ovnp ]
then
    sudo cp app/vpn/*.ovpn /etc/openvpn/client.conf
else 
    echo "OVPN file not exist!"
fi