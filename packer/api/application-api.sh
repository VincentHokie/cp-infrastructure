#!/bin/bash -eux

apt-get -y install nginx
sed -i -e '0,/root \/usr\/share\/nginx\/html/s//root \/home\/vincentasantehokie\/build' /etc/nginx/sites-available/default


# install git, needed for acquiring webapp source code
apt-get -y install git

cd ~

# get repo files on the instance
git clone https://github.com/VincentHokie/andela-flask-api

# for the flask api
sudo apt-get install -y python python-pip python-virtualenv gunicorn nginx

#install uwsgi outside of virtualenv
sudo pip install virtualenv

cd /home/ubuntu/andela-flask-api
virtualenv --python=python3 .
source bin/activate
pip install -r requirements.txt


# create nginx config file
echo "server {
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
    location /static {
        alias  /home/ubuntu/andela-flask-api/app/static/;
    }
}" >> andela-flask-api

# move nginx configs into the sites-available directory
sudo mv andela-flask-api /etc/nginx/sites-available/andela-flask-api

# delete default nginx config
sudo rm /etc/nginx/sites-enabled/default

# create a symbolic link from our new configs to the sites-enabled directory
sudo ln -s /etc/nginx/sites-available/andela-flask-api /etc/nginx/sites-enabled/




# install supervisor
sudo apt-get install -y supervisor

echo "[program:andela_flask_api]
environment=DEBUG=True,CSRF_ENABLED=True,SQLALCHEMY_TRACK_MODIFICATIONS=False,DB='andela-flask-api',USER='postgres',PASSWORD='postgres',HOST='localhost',PORT=5432,HEROKU_POSTGRESQL_CRIMSON_URL='postgresql://postgres:postgres@35.225.22.19:5432/andela-flask-api',WTF_CSRF_ENABLED=False,SECRET_KEY='youll-never-know-what-it-is-coz-its-secret',MAIL_SERVER='smtp.sendgrid.net',MAIL_PORT=2525,MAIL_USE_TLS=False,MAIL_USE_SSL=True,MAIL_USERNAME='apikey',MAIL_PASSWORD='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',MAIL_DEFAULT_SENDER='andelatestmail@gmail.com'
command = /home/ubuntu/andela-flask-api/bin/gunicorn app:app -b localhost:8000
directory = /home/ubuntu/andela-flask-api
user = ubuntu
autostart=true
stderr_logfile=/var/log/supervisor/test.err.log
stdout_logfile=/var/log/supervisor/test.out.log" >> andela-flask-api.conf

sudo mv andela-flask-api.conf /etc/supervisor/conf.d/andela-flask-api.conf


# reread, update and restart supervisor
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start andela_flask-api

#export all env variables for initial db setup if youd like to test the virtualenv first
# export DEBUG=True
# export CSRF_ENABLED=True
# export SQLALCHEMY_TRACK_MODIFICATIONS=False

# export DB='andela-flask-api'
# export USER='postgres'
# export PASSWORD='postgres'
# export HOST='localhost'
# export PORT=5432
# export HEROKU_POSTGRESQL_CRIMSON_URL="postgresql://postgres:postgres@35.225.22.19:5432/andela-flask-api"

# export WTF_CSRF_ENABLED=False
# export SECRET_KEY='youll-never-know-what-it-is-coz-its-secret'
# export MAIL_SERVER='smtp.googlemail.com'
# export MAIL_PORT=465
# export MAIL_USE_TLS=False
# export MAIL_USE_SSL=True
# export MAIL_USERNAME="andelatestmail"
# export MAIL_PASSWORD="andelatestmail1"
# export MAIL_DEFAULT_SENDER="andelatestmail@gmail.com"

# reload nginx to serve from the directory
service nginx reload

echo 'Environment is ready, you should fork and clone the repo now.'