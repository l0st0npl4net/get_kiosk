#!/bin/bash
sleep 50
sudo systemctl start xsst-iiko
sleep 10
export DISPLAY=:0
export XAUTHORITY=/home/proxyuser/.Xauthority
xset s off
xset s noblank
xset -dpms
