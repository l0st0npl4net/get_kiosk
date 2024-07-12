#! /bin/sh

sudo useradd -p proxyuser -s /bin/bash -m proxyuser
sudo echo 'proxyuser:proxyuser' | sudo chpasswd
mkdir /home/proxyuser
cp -rT /etc/skel /home/proxyuser
chown -R proxyuser:proxyuser /home/proxyuser
chsh -s /bin/bash proxyuser

echo "PROXYUSER setup complete!"