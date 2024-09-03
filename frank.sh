#! /bin/sh

apt-get -y install sudo
sudo apt-get -y install \
                    git \
                    wget \
                    dialog \
                    nano \

cd /tmp                      
git clone -b frank --depth 1 https://github.com/l0st0npl4net/get_kiosk.git

sudo chmod -R 777 /tmp/get_kiosk

cd get_kiosk && ./install.sh



