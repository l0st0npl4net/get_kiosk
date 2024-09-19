#! /bin/sh

apt-get -y install sudo
sudo apt-get -y install \
                    wget \
                    dialog \
                    nano \
                    unzip

cd /tmp
if [ ! -d "get_kiosk-frank" ]; then                      
    wget 'https://github.com/l0st0npl4net/get_kiosk/archive/refs/heads/frank.zip'
    unzip frank.zip
fi

sudo chmod -R 777 /usr/shareget_kiosk-frank

cd get_kiosk-frank && ./install.sh



