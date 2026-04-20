#!/bin/bash


sudo apt-get -y install cups
sudo cat << EOF > /etc/cups/cupsd.conf
# Show troubleshooting information in error_log.
LogLevel debug
PageLogFormat
MaxLogSize 100
Port 631
Listen /var/run/cups/cups.sock
Browsing On
BrowseLocalProtocols dnssd
DefaultAuthType Basic
WebInterface Yes
<Location />
  Order allow,deny
  Allow from all
</Location>
<Location /admin>
  Order allow,deny
  Allow from all
</Location>
<Location /admin/conf>
  AuthType Default
  Require user @SYSTEM
  Order allow,deny
  Allow from all
</Location>
<Location /admin/log>
  AuthType Default
  Require user @SYSTEM
  Order allow,deny
  Allow from all
</Location>
<Policy default>
  JobPrivateAccess default
  JobPrivateValues default
  SubscriptionPrivateAccess default
  SubscriptionPrivateValues default
  <Limit Create-Job Print-Job Print-URI Validate-Job>
    Order deny,allow
  </Limit>
  <Limit Send-Document Send-URI Hold-Job Release-Job Restart-Job Purge-Jobs Set-Job-Attributes Create-Job-Subscription Renew-Subscription Cancel-Subscription Get-Notifications Reprocess-Job Cancel-Current-Job Suspend-Current-Job Resume-Job Cancel-My-Jobs Close-Job CUPS-Move-Job CUPS-Get-Document>
    Require user @OWNER @SYSTEM
    Order deny,allow
  </Limit>
  <Limit CUPS-Add-Modify-Printer CUPS-Delete-Printer CUPS-Add-Modify-Class CUPS-Delete-Class CUPS-Set-Default CUPS-Get-Devices>
    AuthType Default
    Require user @SYSTEM
    Order deny,allow
  </Limit>
  <Limit Pause-Printer Resume-Printer Enable-Printer Disable-Printer Pause-Printer-After-Current-Job Hold-New-Jobs Release-Held-New-Jobs Deactivate-Printer Activate-Printer Restart-Printer Shutdown-Printer Startup-Printer Promote-Job Schedule-Job-After Cancel-Jobs CUPS-Accept-Jobs CUPS-Reject-Jobs>
    AuthType Default
    Require user @SYSTEM
    Order deny,allow
  </Limit>
  <Limit Cancel-Job CUPS-Authenticate-Job>
    Require user @OWNER @SYSTEM
    Order deny,allow
  </Limit>
  <Limit All>
    Order deny,allow
  </Limit>
</Policy>
<Policy authenticated>
  JobPrivateAccess default
  JobPrivateValues default
  SubscriptionPrivateAccess default
  SubscriptionPrivateValues default
  <Limit Create-Job Print-Job Print-URI Validate-Job>
    AuthType Default
    Order deny,allow
  </Limit>
  <Limit Send-Document Send-URI Hold-Job Release-Job Restart-Job Purge-Jobs Set-Job-Attributes Create-Job-Subscription Renew-Subscription Cancel-Subscription Get-Notifications Reprocess-Job Cancel-Current-Job Suspend-Current-Job Resume-Job Cancel-My-Jobs Close-Job CUPS-Move-Job CUPS-Get-Document>
    AuthType Default
    Require user @OWNER @SYSTEM
    Order deny,allow
  </Limit>
  <Limit CUPS-Add-Modify-Printer CUPS-Delete-Printer CUPS-Add-Modify-Class CUPS-Delete-Class CUPS-Set-Default>
    AuthType Default
    Require user @SYSTEM
    Order deny,allow
  </Limit>
  <Limit Pause-Printer Resume-Printer Enable-Printer Disable-Printer Pause-Printer-After-Current-Job Hold-New-Jobs Release-Held-New-Jobs Deactivate-Printer Activate-Printer Restart-Printer Shutdown-Printer Startup-Printer Promote-Job Schedule-Job-After Cancel-Jobs CUPS-Accept-Jobs CUPS-Reject-Jobs>
    AuthType Default
    Require user @SYSTEM
    Order deny,allow
  </Limit>
  <Limit Cancel-Job CUPS-Authenticate-Job>
    AuthType Default
    Require user @OWNER @SYSTEM
    Order deny,allow
    Allow all
  </Limit>
  <Limit All>
    Order deny,allow
  </Limit>
</Policy>
<Policy kerberos>
  JobPrivateAccess default
  JobPrivateValues default
  SubscriptionPrivateAccess default
  SubscriptionPrivateValues default
  <Limit Create-Job Print-Job Print-URI Validate-Job>
    AuthType Negotiate
    Order deny,allow
  </Limit>
  <Limit Send-Document Send-URI Hold-Job Release-Job Restart-Job Purge-Jobs Set-Job-Attributes Create-Job-Subscription Renew-Subscription Cancel-Subscription Get-Notifications Reprocess-Job Cancel-Current-Job Suspend-Current-Job Resume-Job Cancel-My-Jobs Close-Job CUPS-Move-Job CUPS-Get-Document>
    AuthType Negotiate
    Require user @OWNER @SYSTEM
    Order deny,allow
  </Limit>
  <Limit CUPS-Add-Modify-Printer CUPS-Delete-Printer CUPS-Add-Modify-Class CUPS-Delete-Class CUPS-Set-Default>
    AuthType Default
    Require user @SYSTEM
    Order deny,allow
  </Limit>
  <Limit Pause-Printer Resume-Printer Enable-Printer Disable-Printer Pause-Printer-After-Current-Job Hold-New-Jobs Release-Held-New-Jobs Deactivate-Printer Activate-Printer Restart-Printer Shutdown-Printer Startup-Printer Promote-Job Schedule-Job-After Cancel-Jobs CUPS-Accept-Jobs CUPS-Reject-Jobs>
    AuthType Default
    Require user @SYSTEM
    Order deny,allow
  </Limit>
  <Limit Cancel-Job CUPS-Authenticate-Job>
    AuthType Negotiate
    Require user @OWNER @SYSTEM
    Order deny,allow
  </Limit>
  <Limit All>
    Order deny,allow
  </Limit>
</Policy>
EOF

if [[ -f /etc/sst-iiko/print_settings.ini ]] || [[ -d /etc/sst-iiko/templates ]]; then 
      echo "Already exists!"
else 
      echo > /etc/sst-iiko/print_settings.ini
      cat << EOF > /etc/sst-iiko/print_settings.ini
[Templates]
List/size = 1
List/1/name = header
List/2/name = position
List/3/name = total
List/4/name = tax
List/5/name = prepayment
List/6/name = payment
List/7/name = afterpayment
List/8/name = empty
List/9/name = footer

[Document]
Font-size = 10
Printer = UNSET
Line-width = 80
EOF
      sudo mkdir /etc/sst-iiko/templates
      echo > /etc/sst-iiko/templates/receipt.rtdf
      cat << EOF > /etc/sst-iiko/templates/receipt.rtdf
<center><h1>Кассовый чек</h1></center>
<br>
{{Positions}}
<hr>
<table style=\"width:100%\">
    <tr>
        <td width=80%>Итог</td>
        <td width=20%>={{Summ}}</td>
    </tr>
</table>   
<hr>
{{Vats}}
{{Payments}}
{{Organization}}
<br>
<hr>

{{ReceiptType}}
<br>
{{SaleDateTime}}
<br>
<center>
<img src="file://{{FDQrFile}}">
<p>_____________________________________________________________________</p>
<p>Ваш номер заказа</p>
<p style="font-size:100px">{{OrderNumber}}</p>
<p >{{additionalStrings}}</p>
</center>

{{additionalStrings}}
EOF
fi


sudo chmod 755 -R /etc/cups/
sudo apt-get -y install foomatic-db foomatic-db-engine
sudo usermod -a -G lpadmin proxyuser
sudo usermod -a -G dialout lp
sudo usermod -a -G dialout proxyuser

printers_list=(0 "REXOD" off
        1 "SAM4S 102c" off
        2 "Custom VKP80II(2)" off
        3 "Custom VKP80III(3)" off
        4 "ATOL RP326" off
        5 "POScenter RP-100 USE" off)

ch=$(dialog --separate-output \
                --backtitle "УСТАНОВЩИК GET-KIOSK" \
                --title "Внедрение: Чековый принтер" \
                --checklist "Выберите нужную модель(SPACE - выбрать):" \
                30 45 20 \
                  "${printers_list[@]}" 2>&1 >/dev/tty)
clear
printer=/

for choice in $ch
do
      case $choice in
            0) printer="Universal";;
            1) printer="Sam4s_102c";;
            2) printer="Custom_VKP80II_2";;
            3) printer="Custom_VKP80III_3";;
            4) printer="Atol_RP326";;
            5) printer="POScenter_RP-100_VCOM";;

      esac
done


sudo cp app/printer/"$printer"/raster_to_printer /usr/lib/cups/filter/
sudo chmod a+x /usr/lib/cups/filter/raster_to_printer
sync

CONNECTION=/
PRINTER_URI=/
terminal_list=(
        0 "USB" off
        1 "VCOM" off
        2 "NETWORK" off)

ch=$(dialog --separate-output \
                --backtitle "УСТАНОВЩИК GET-KIOSK" \
                --title "Внедрение: Способ подключения" \
                --checklist "Выберите подключение(SPACE - выбрать):" \
                30 45 20 \
                  "${terminal_list[@]}" 2>&1 >/dev/tty)
clear

for choice in $ch
do
      case $choice in
            0) CONNECTION="USB";;
            1) CONNECTION="VCOM";;
            2) CONNECTION="NETWORK";;
      esac
done

if [ "$CONNECTION" = "USB"]; then
    DIRECT_URI=$(sudo lpinfo -v | grep "direct usb")
    PRINTER_URI=${DIRECT_URI##* }

elif ["$CONNECTION" = "VCOM"]; then
    source app/printer/vcom.env
    sudo echo ${!printer} >> /etc/udev/rules.d/printer.rules
    cat << EOF > /etc/rc.local
#!/bin/sh
sudo chmod -R 666 /dev/ttyACM0
sudo chmod -R 666 /dev/ttyACM1
sudo chmod -R 666 /dev/printer
exit 0
EOF

    sudo chmod +x /etc/rc.local

    cat > /etc/systemd/system/rc-local.service <<EOF
[Unit] 
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl enable rc-local
    sudo systemctl restart rc-local
    PRINTER_URI=serial:/dev/printer?baud=115200

elif ["$CONNECTION" = "NETWORK"]; then
    read -p "Printer IP: " IP
    read -p "Printer Port: " PORT
    PRINTER_URI=socket://${IP}:${PORT}
fi

sudo lpadmin -x $printer
sudo lpadmin -p SAM4S -E -v $PRINTER_URI -P /tmp/get_kiosk-main/app/printer/driver/$printer/*.ppd

# sudo lp -d SAM4S /usr/share/cups/data/default-testpage.pdf
# sudo lp -d SAM4S_VCOM /usr/share/cups/data/default-testpage.pdf
# sudo lp -d REXOD /usr/share/cups/data/default-testpage.pdf
# sudo lp -d VKP80 /usr/share/cups/data/default-testpage.pdf

sudo crudini --set  /etc/sst-iiko/print_settings.ini Document Printer $printer \
             --set  /etc/sst-iiko/settings.ini FP fiscal\type UNSET \
             --set  /etc/sst-iiko/settings.ini FP printer\SETTINGS_PATH /etc/sst-iiko/print_settings.ini \
             --set  /etc/sst-iiko/settings.ini FP printer\TEMPLATE_PATH /etc/sst-iiko/templates/ \
             --set  /etc/sst-iiko/settings.ini FP printer\advancedTemplates true \
             --set  /etc/sst-iiko/settings.ini FP printer\type System \
             --set  /etc/sst-iiko/settings.ini FP type Compound

sudo sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" /etc/sst-iiko/settings.ini

echo "Printer almost setup complete!"

