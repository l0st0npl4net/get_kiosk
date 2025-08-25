#! /bin/sh

#Заходим под рутом и добавляем пользователя proxyuser
read -p "Please, enter Aauthorized key: " KEY
echo "proxyuser ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/010_proxyuser-nopasswd
sudo mkdir /home/proxyuser/.ssh 

read -p "Please, enter Aauthorized key: " KEY

cat > authorized_keys <<EOF
$KEY
EOF

#Устанавливаем и настраиваем sst-iiko
DEBIAN=$(cat /etc/debian_version | tee)
SOURCE=$(printf "%.0f" "$DEBIAN")

sudo apt-get -y install gnupg 
echo "deb http://repo.open-s.info/ buster main trunk" | sudo tee -a /etc/apt/sources.list.d/bos.list
wget -qO - http://repo.open-s.info/aptly.gpg.key | sudo apt-key add

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

sudo systemctl enable sst-iiko
sudo systemctl start sst-iiko
sudo cp -r app/kiosk/sst-iiko /etc
sudo cp -r app/kiosk/img/* /opt/sst-iiko/img
sudo systemctl enable systemd-networkd-wait-online.service

echo "GET KIOSK SOFTWARE setup complete!"
