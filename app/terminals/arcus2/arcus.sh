#! /bin/sh


sudo cp -r app/terminals/arcus2/driver/* /home/reg/
sudo chmod 777 -R /home/reg

sudo dpkg --add-architecture i386
sudo apt-get update

sudo apt-get -y install \
                libc6:i386
                libstdc++6:i386 \
                libncurses5 \
                libncurses5:i386 \
                libstdc++5 \
                libstdc++5:i386

sudo crudini --set  /etc/sst-iiko/settings.ini Terminal path /home/reg/arcus/cashreg \
             --set  /etc/sst-iiko/settings.ini Terminal receiptPath /home/reg/arcus/cpd.out \
             --set  /etc/sst-iiko/settings.ini Terminal answerPath /home/reg/arcus/rc.out \
             --set  /etc/sst-iiko/settings.ini Terminal type Arcus
sudo sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" /etc/sst-iiko/settings.ini

sudo /home/reg/arcus/cahsreq /o7

echo "ARCUS TERMINAL setup complete!"

