#! /bin/sh

DEBIAN=$(cat /etc/debian_version | tee)
SOURCE=$(printf "%.0f" "$DEBIAN")

#Заходим под рутом и добавляем пользователя proxyuser
echo "proxyuser ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/010_proxyuser-nopasswd
sudo mkdir /home/proxyuser/.ssh 
sudo cp app/kiosk/authorized_keys /home/proxyuser/.ssh/authorized_keys


#Устанавливаем и настраиваем sst-iiko
sudo apt-get -y install gnupg 
echo "deb http://repo.open-s.info/ buster main" | sudo tee -a /etc/apt/sources.list.d/bos.list
wget -qO - http://repo.open-s.info/aptly.gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/aptly.gpg

sudo cp app/kiosk/sources/d11sources.txt /etc/apt/sources.list
sudo apt-get update
sudo apt-get -y install libicu67
sudo apt-get -y install libtiff5
sudo apt-get -y install libssl1.1


sudo cp app/kiosk/sources/d"$SOURCE"sources.txt /etc/apt/sources.list

sudo apt-get update

read -p "SST-IIKO Version [Enter for latest release]: " VERSION

if [ -z "$VERSION"]; then
    sudo apt-get -y install sst-iiko 
else 
    sudo apt-get -y install sst-iiko="$VERSION";
fi

read -p "Enter Main Kassa Local IP Adress: " K_IP

sudo systemctl enable sst-iiko
sudo systemctl start sst-iiko
sudo cp -r app/kiosk/sst-iiko /etc

sudo crudini --set  /etc/sst-iiko/settings.ini iiko host ws://${K_IP}

sudo mkdir /opt/sst-iiko/img
sudo systemctl enable systemd-networkd-wait-online.service

echo "GET KIOSK SOFTWARE setup complete!"
