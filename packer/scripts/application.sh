#!/bin/bash -eux

apt-get -y install nginx
sed -i -e '0,/root \/usr\/share\/nginx\/html/s//root \/home\/vagrant\/react-cp-client/build' /etc/nginx/sites-available/default


# install git, needed for acquiring webapp source code
apt-get -y install git

# remove old node just in case
apt-get remove --purge node

# application and build process required packages
# add Node.js maintained repositories
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -

# for tests and build
sudo apt-get -y install nodejs

cd ~/react-cp-client

npm install

npm run build

# reload nginx to serve from the directory
service nginx reload

echo 'Environment is ready, you should fork and clone the repo now.'