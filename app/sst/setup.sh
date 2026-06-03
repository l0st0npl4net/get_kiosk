#! /bin/sh

DEBIAN=$(cat /etc/debian_version | tee)
SOURCE=$(printf "%.0f" "$DEBIAN")
DEBIAN_CODENAME=$(. /etc/os-release && echo $VERSION_CODENAME)


#Заходим под рутом и добавляем пользователя proxyuser
echo "proxyuser ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/010_proxyuser-nopasswd
sudo mkdir /home/proxyuser/.ssh

read -p "Please, enter Authorized key: " KEY

cat > authorized_keys <<EOF
$KEY
EOF

sudo mv authorized_keys /home/proxyuser/..ssh/authorized_keys


#Добавляем наш репозиторий
sudo apt-get -y install gnupg
echo "deb http://repo.open-s.info/ buster main" | sudo tee -a /etc/apt/sources.list.d/bos.list
wget -qO - http://repo.open-s.info/aptly.gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/aptly.gpg


#Устанавливаем необмходимые библиотеки - пока что это костыль и он есть
sudo truncate -s 0 /etc/apt/sources.list
sudo cat << EOL > /etc/apt/sources.list
<<<<<<< HEAD
deb http://deb.debian.org/debian bullseye main contrib non-free
deb-src http://deb.debian.org/debian bullseye main contrib non-free

deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free

deb http://deb.debian.org/debian bullseye-backports main contrib non-free
deb-src http://deb.debian.org/debian bullseye-backports main contrib non-free

deb http://security.debian.org/debian-security/ bullseye-security main contrib non-free
deb-src http://security.debian.org/debian-security/ bullseye-security main contrib non-free
=======
deb http://mirror.yandex.ru/debian trixie main contrib non-free
deb http://mirror.yandex.ru/debian trixie-updates main contrib non-free
deb http://security.debian.org/debian-security trixie-security main contrib non-free
>>>>>>> 6bf74a3154ffa7207409e8ced29ce6767935b0e7
EOL

sudo apt-get update
sudo apt-get -y install libicu67
sudo apt-get -y install libtiff5
sudo apt-get -y install libssl1.1


#Установка пакетов SST-IIKO
sudo cat << EOL > /etc/apt/sources.list
<<<<<<< HEAD
deb http://mirror.yandex.ru/debian "$DEBIAN_CODENAME" main contrib non-free
deb http://mirror.yandex.ru/debian "$DEBIAN_CODENAME"-updates main contrib non-free
deb http://security.debian.org/debian-security "$DEBIAN_CODENAME"-security main contrib non-free
=======
deb http://deb.debian.org/debian/ "$DEBIAN_CODENAME" main
deb-src http://deb.debian.org/debian/ "$DEBIAN_CODENAME" main

deb http://security.debian.org/debian-security "$DEBIAN_CODENAME"-security main
deb-src http://security.debian.org/debian-security "$DEBIAN_CODENAME"-security main

deb http://deb.debian.org/debian/ "$DEBIAN_CODENAME"-updates main
deb-src http://deb.debian.org/debian/ "$DEBIAN_CODENAME"-updates main
>>>>>>> 6bf74a3154ffa7207409e8ced29ce6767935b0e7
EOL

sudo apt-get update

read -p "SST-IIKO Version [Enter for latest release]: " VERSION

if [ -z "$VERSION"]; then
    sudo apt-get -y install sst-iiko
else
    sudo apt-get -y install sst-iiko="$VERSION";
fi


#Добавление ряда параметров в конфиг
read -p "Enter Main Kassa Local IP Adress: " K_IP

sudo systemctl enable sst-iiko
sudo systemctl start sst-iiko

sudo crudini --set  /etc/sst-iiko/settings.ini FP type Dummy \
             --set  /etc/sst-iiko/settings.ini iiko host ws://${K_IP} \
             --set  /etc/sst-iiko/logger.ini File minLevelRelease Debug

sudo mkdir /opt/sst-iiko/img
sudo touch /etc/sst-iiko/templates/header
sudo systemctl enable systemd-networkd-wait-online.service

echo "GET KIOSK SOFTWARE setup complete!"
