#!/usr/bin/env bash

apt-get update
apt-get install -y mysql-server apache2 php php-mysql php-zip

echo "default-authentication-plugin=mysql_native_password" >> /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql

MYSQL_USER=wordpress
MYSQL_PASSWORD=QOV8L6JT2CHWDhpv
MYSQL_HOST=localhost
MYSQL_DB=mt
mysql -u root -e "CREATE DATABASE $MYSQL_DB;"
mysql -u root -e "CREATE USER $MYSQL_USER@$MYSQL_HOST IDENTIFIED WITH mysql_native_password BY '$MYSQL_PASSWORD';"
mysql -u root -e "GRANT ALL ON $MYSQL_DB.* TO $MYSQL_USER@$MYSQL_HOST;"

rm -fr /var/www/html/*
chgrp www-data /var/www/html
chmod g+w /var/www/html
cd /var/www/html
sudo -u www-data wget https://github.com/mplesha/NoviNano/releases/download/v1.0/20180706_novinano_mt_b2a03d4e0cbc53e87026180706071957_installer.php
sudo -u www-data wget https://github.com/mplesha/NoviNano/releases/download/v1.0/20180706_novinano_mt_b2a03d4e0cbc53e87026180706071957_archive.zip

shutdown -r now

