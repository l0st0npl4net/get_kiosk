#! /bin/bash

#Запуск
sudo systemctl enable x11vnc.service
sudo systemctl enable xorg.service
sudo systemctl enable xsst-iiko

sudo systemctl start xsst-iiko
sudo systemctl enable xsst-iiko

sudo systemctl disable sst-iiko

sudo systemctl start xorg.service
sudo systemctl start x11vnc
