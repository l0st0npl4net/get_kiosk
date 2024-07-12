#! /bin/bash 

#Устанавливаем и настраиваем ВПН
sudo apt-get -y install openvpn
sudo cp app/vpn/openvpn /etc/default/openvpn
sudo systemctl enable openvpn.service

read -p "VPN file download link: " vpnvar 
wget $vpnvar -P app/vpn

if [ -e vpn/*.ovnp ]
then
    sudo cp app/vpn/*.ovpn /etc/openvpn/client.conf
    echo "OpenVPN setup complete (reboot required)"
else 
    echo "OVPN file not exist!"
fi