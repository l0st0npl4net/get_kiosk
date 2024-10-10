#! /bin/bash

#Остановка
sudo systemctl disable x11vnc.service
sudo systemctl disable xorg.service
sudo systemctl disable xsst-iiko

sudo systemctl stop xsst-iiko

sudo systemctl enable sst-iiko
sudo systemctl start sst-iiko

sudo systemctl stop xorg.service
sudo systemctl stop x11vnc
