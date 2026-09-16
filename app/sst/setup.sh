#! /bin/sh

DEBIAN=$(cat /etc/debian_version | tee)
SOURCE=$(printf "%.0f" "$DEBIAN")
DEBIAN_CODENAME=$(. /etc/os-release && echo $VERSION_CODENAME)


#Заходим под рутом и добавляем пользователя proxyuser
echo "proxyuser ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/010_proxyuser-nopasswd
sudo mkdir /home/proxyuser/.ssh

read -p "Please, enter Authorized key: " KEY

cat > authorized_keys << EOF
$KEY
EOF

mkdir /home/proxyuser/.ssh
sudo mv authorized_keys /home/proxyuser/.ssh/authorized_keys


#Добавляем наш репозиторий
sudo apt-get -y install gnupg

sudo cat << 'EOF' > /etc/apt/sources.list.d/bos.list
deb http://repo.open-s.info/ buster main
EOF


wget -qO - http://repo.open-s.info/aptly.gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/aptly.gpg


#Устанавливаем необмходимые библиотеки - пока что это костыль и он есть
sudo apt-get -y install libtiff-dev

sudo wget -O /tmp/libtiff5.deb http://ftp.ru.debian.org/debian/pool/main/t/tiff/libtiff5-dev_4.7.2-1_amd64.deb
sudo wget -O /tmp/libicu67.deb https://snapshot.debian.org/archive/debian-security/20250615T141349Z/pool/updates/main/i/icu/libicu67_67.1-7%2Bdeb11u1_amd64.deb
sudo wget -O /tmp/libssl1.1.deb https://snapshot.debian.org/archive/debian-security/20260615T025018Z/pool/updates/main/o/openssl/libssl1.1_1.1.1w-0%2Bdeb11u8_amd64.deb
sudo wget -O /tmp/libtiff5-dev.deb http://ftp.ru.debian.org/debian/pool/main/t/tiff/libtiff5-dev_4.7.2-1_amd64.deb

sudo dpkg -i /tmp/libtiff5-dev.deb
sudo dpkg -i /tmp/libtiff5.deb
sudo dpkg -i /tmp/libicu67.deb
sudo dpkg -i /tmp/libssl1.1.deb


#sudo truncate -s 0 /etc/apt/sources.list
#sudo cat << EOL > /etc/apt/sources.list
#deb http://archive.debian.org/debian bullseye main contrib non-free
#deb http://archive.debian.org/debian bullseye-updates main contrib non-free
#deb http://security.debian.org/debian-security bullseye-security main contrib non-free
#EOL
#
#sudo apt-get update
#sudo apt-get -y install libicu67
#sudo apt-get -y install libtiff5
#sudo apt-get -y install libssl1.1


#Установка пакетов SST-IIKO
sudo cat << EOL > /etc/apt/sources.list

deb http://mirror.yandex.ru/debian "$DEBIAN_CODENAME" main contrib non-free
deb http://mirror.yandex.ru/debian "$DEBIAN_CODENAME"-updates main contrib non-free
deb http://security.debian.org/debian-security "$DEBIAN_CODENAME"-security main contrib non-free
EOL

sudo apt-get update

read -p "SST-IIKO Version [Enter for latest release]: " VERSION

if [ -z "$VERSION" ]; then
    sudo apt-get -y install sst-iiko
else
    sudo apt-get -y install sst-iiko="$VERSION";
fi


#Добавление ряда параметров в конфиг
read -p "Enter Main Kassa Local IP Adress: " K_IP

sudo systemctl enable sst-iiko
sudo systemctl start sst-iiko

sudo crudini --set  /etc/sst-iiko/settings.ini FP type Dummy \
             --set  /etc/sst-iiko/settings.ini iiko host ws://${K_IP}

sudo mkdir /opt/sst-iiko/img
sudo mkdir /etc/sst-iiko/templates
sudo touch /etc/sst-iiko/templates/header
sudo systemctl enable systemd-networkd-wait-online.service

echo "GET KIOSK SOFTWARE setup complete!"
