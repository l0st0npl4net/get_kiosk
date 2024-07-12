#! /bin/sh

sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get -y install libc6:i386 libncurses5:i386 libstdc++6:i386 libgtk2.0-0:i386

sudo chmod 777 -R /opt/
sudo chmod 777 -R /tmp/

sudo cp app/fito/Fito.txt /opt/Fito.txt
sudo cp app/fito/install_comproxy.sh /tmp/install_comproxy.sh

sudo apt install socat -y

sudo chmod +x install_comproxy.sh
sudo /tmp/install_comproxy.sh

sudo service comproxy start

echo "Proccess complete!"