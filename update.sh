#! /bin/sh

sudo cp -R img/* /opt/sst-iiko/img
sudo cp -R fonts/* /usr/share/fonts/truetype/

sudo apt-get update
sudo apt-get -y install sst-iiko=0.29.0.fcfc6ddf
sudo systemctl restart sst-iiko

tail -f `/bin/ls -1td /var/log/sst-iiko/*| /usr/bin/head -n1` -n 100