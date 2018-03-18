#!/bin/bash -eux

apt-get -y install nginx
sed -i -e '0,/root \/usr\/share\/nginx\/html/s//root \/home\/vincentasantehokie\/build' /etc/nginx/sites-available/default


# install git, needed for acquiring webapp source code
apt-get -y install git

cd ~

# get repo files on the instance
git clone https://github.com/VincentHokie/andela-react-client

# go onto the correct branch
git checkout origin/es6-adherence

# remove old node just in case
apt-get remove --purge node

# for the flask api
sudo apt-get install python-pip python-dev nginx

#install uwsgi outside of virtualenv
sudo pip install virtualenv
- create virtualenv
- install requirements

#postgres requirements
sudo apt-get -y install postgresql postgresql-client postgresql-contrib
#login with default postgres user "postgres"
sudo -u postgres psql postgres
#set password for postgres
\password postgres
#export all env variables
#login to postgres and create db
# then initailize migrations, makemigrations and upgrade
#test app
python run.py

https://realpython.com/blog/python/kickstarting-flask-on-ubuntu-setup-and-deployment/#profit - replicate this one time

# create uwsgi conf file xx.ini
andela-flask-api.ini

# create an upstart script
/etc/init/andela-flask-api.conf


# application and build process required packages
# add Node.js maintained repositories
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -

# for tests and build
sudo apt-get -y install nodejs

cd ~

npm install

npm run build

# reload nginx to serve from the directory
service nginx reload

echo 'Environment is ready, you should fork and clone the repo now.'