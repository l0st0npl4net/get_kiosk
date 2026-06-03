#! /bin/sh


read -p "Atol Test-Driver Version [Enter for latest release]: " VERSION

sudo apt-get -y install fptr10-test-util="$VERSION"

sudo crudini --set  /etc/sst-iiko/settings.ini FP type Atol
sudo sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" /etc/sst-iiko/settings.ini

echo "ATOL driver setup complete!"