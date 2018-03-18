#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -o errexit

# mysqldump |gzip. The exit status of the last command that threw a non-zero exit code is returned.
set -o pipefail

sudo apt-get -y install nginx

# what exactly I do
# sudo sed -i -e '0,/root \/usr\/share\/nginx\/html/s//root \/home\/vincentasantehokie\/build' /etc/nginx/sites-available/default

cd ~

# get repo files on the instance
git clone https://github.com/VincentHokie/andela-react-client

cd ~/andela-react-client

# go onto the correct branch
git checkout origin/es6-adherence

# remove old node just in case
sudo apt-get remove --purge node

# application and build process required packages
# add Node.js maintained repositories
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -

# for tests and build
sudo apt-get -y install nodejs

cd ~/andela-react-client

npm install

npm run build

# create nginx config file
echo "server {
	listen 80 default_server;
	server_name localhost;
	
	root /home/ubuntu/andela-react-client/build;
	index index.html index.html;

	location / {
		try_files \$uri \$uri/ =404;
	}
}" >> client

# move nginx configs into the sites-available directory
sudo mv client /etc/nginx/sites-available/client

# delete default nginx config
sudo rm /etc/nginx/sites-enabled/default

# create a symbolic link from our new configs to the sites-enabled directory
sudo ln -s /etc/nginx/sites-available/client /etc/nginx/sites-enabled/

# reload nginx to serve from the directory
sudo nginx -t
sudo /etc/init.d/nginx restart

echo 'Environment is ready, you should fork and clone the repo now.'