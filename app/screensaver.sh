#! /bin/sh

sudo crudini --set /etc/systemd/system/xsst-iiko.service Service ExecStartPre "/bin/sh -c 'DISPLAY=:0 xset s off'" \
             --set /etc/systemd/system/xsst-iiko.service Service ExecStartPre "/bin/sh -c 'DISPLAY=:0 xset -dpms'" \
             --set /etc/systemd/system/xsst-iiko.service Service ExecStartPre "/bin/sh -c 'DISPLAY=:0 xset s noblank'"

sudo systemctl daemon-reload
sudo systemctl rastart xsst-iiko

echo "Screensaver disabled!"