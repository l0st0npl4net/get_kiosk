#! /bin/sh


sudo cp -r app/terminals/arcus2/driver/* /home/reg/
sudo chmod 777 -R /home/reg

sudo dpkg --add-architecture i386
sudo apt-get update

sudo apt-get -y install \
                libc6 \
                libc6:i386 \
                libstdc++6 \
                libstdc++6:i386 \

sudo wget -O /tmp/libncurses5_6.4-4_amd64.deb http://ftp.ru.debian.org/debian/pool/main/n/ncurses/libncurses5_6.4-4_amd64.deb
sudo wget -O /tmp/libncurses5_6.4-4_i386.deb http://ftp.ru.debian.org/debian/pool/main/n/ncurses/libncurses5_6.4-4_i386.deb
sudo wget -O /tmp/libstdc++5_3.3.6-34_amd64.deb http://ftp.ru.debian.org/debian/pool/main/g/gcc-3.3/libstdc++5_3.3.6-34_amd64.deb
sudo wget -O /tmp/libstdc++5_3.3.6-34_i386.deb http://ftp.ru.debian.org/debian/pool/main/g/gcc-3.3/libstdc++5_3.3.6-34_i386.deb

sudo dpkg -i /tmp/libncurses5_6.4-4_amd64.deb 
sudo dpkg -i /tmp/libncurses5_6.4-4_i386.deb 
sudo dpkg -i /tmp/libstdc++5_3.3.6-34_amd64.deb
sudo dpkg -i /tmp/libstdc++5_3.3.6-34_i386.deb

sudo crudini --set  /etc/sst-iiko/settings.ini Terminal path /home/reg/arcus/cashreg \
             --set  /etc/sst-iiko/settings.ini Terminal receiptPath /home/reg/arcus/cpd.out \
             --set  /etc/sst-iiko/settings.ini Terminal answerPath /home/reg/arcus/rc.out \
             --set  /etc/sst-iiko/settings.ini Terminal type Arcus
sudo sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" /etc/sst-iiko/settings.ini

sudo /home/reg/arcus/cahsreq /o7

echo "ARCUS TERMINAL setup complete!"