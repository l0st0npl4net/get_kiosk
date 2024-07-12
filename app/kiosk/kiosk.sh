#! /bin/sh

#Заходим под рутом и добавляем пользователя proxyuser
apt install sudo -y

apt install wget -y

echo "proxyuser ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/010_proxyuser-nopasswd

sudo mkdir /home/proxyuser/.ssh 

sudo cp app/authorized_keys /home/proxyuser/.ssh/authorized_keys


#Устанавливаем и настраиваем sst-iiko
sudo apt install gnupg -y

echo "deb http://repo.open-s.info/ buster main" | sudo tee -a /etc/apt/sources.list.d/bos.list

wget -qO - http://repo.open-s.info/aptly.gpg.key | sudo apt-key add

sudo cp app/sources/d11sources.txt /etc/apt/sources.list

sudo apt update

sudo apt-get -y install libicu67

sudo apt-get -y install libtiff5

sudo apt-get -y install libssl1.1

sudo cp app/sources/d12sources.txt /etc/apt/sources.list

sudo apt update

sudo apt install sst-iiko -y

sudo systemctl enable sst-iiko

sudo service sst-iiko start

sudo cp -r app/kiosk/sst-iiko /etc

sudo mkdir /opt/sst-iiko/img

sudo systemctl enable systemd-networkd-wait-online.service

echo "Proccess complete!"
