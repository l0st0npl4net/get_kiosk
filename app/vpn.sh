#! /bin/bash 

#Устанавливаем и настраиваем ВПН
sudo apt-get -y install openvpn
sudo sed -i -e 's/#AUTOSTART="all"/AUTOSTART="all"/g' /etc/default/openvpn

read -p "OpenVPN configue URL: " VPN_URL
wget $VPN_URL -P app
unzip app/*zip app/
sudo cp app/*.ovpn /etc/openvpn/client/pritunl.conf

sudo systemctl start openvpn-client@pritunl
sudo systemctl enable openvpn-client@pritunl
echo "OpenVPN setup complete! (reboot required)"
