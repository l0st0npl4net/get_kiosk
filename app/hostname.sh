#! /bin/bash

read -p "Enter new Hostname: " NEW_HOSTNAME

sudo hostnamectl set-hostname "$NEW_HOSTNAME"
sudo sed -i "s/127.0.1.1.*/127.0.1.1 $NEW_HOSTNAME/" /etc/hosts

cat /etc/hostname
cat /etc/hosts

echo "Hostname has changed! (reboot required)"