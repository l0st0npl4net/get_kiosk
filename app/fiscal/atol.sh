#! /bin/sh
read -p "Atol Test-Driver Version [Enter for latest release]: " VERSION

sudo apt-get -y install fptr10-test-util="$VERSION"

sudo crudini --set  /etc/sst-iiko/settings.ini FP type Atol
sudo sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" /etc/sst-iiko/settings.ini

if [ -f /etc/sst-iiko/templates/postfiscalAtol.rtdf ]; then
      echo "/etc/sst-iiko/templates/postfiscalAtol.rtdf - Already exists!"
else
      sudo echo > /etc/sst-iiko/templates/postfiscalAtol.rtdf
      sudo cat << 'EOF' > /etc/sst-iiko/templates/postfiscalAtol.rtdf
\\ac\\h2\\w2Номер Вашего заказа
\\_img{{orderNum}}
\\ac\\h2\\w2Локатор
\\_img{{locatorNum}}
{{Slip}{\\\\h2\\\\w2{}
}}
EOF
fi

echo "ATOL driver setup complete!"