#! /bin/bash 

#Устанавливаем и настраиваем ВПН
sudo apt-get -y install openvpn
sudo cp app/vpn/openvpn /etc/default/openvpn

read -p "OpenVPN configue URL: " VPN_URL
wget $VPN_URL -P app/vpn
unzip app/vpn/*zip app/vpn/
sudo cp app/vpn/*.ovpn /etc/openvpn/client/pritunl.conf

sudo systemctl start openvpn-client@pritunl
sudo systemctl enable openvpn-client@pritunl
echo "OpenVPN setup complete! (reboot required)"
