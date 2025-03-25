#!/bin/bash
APACHE=/etc/apache2/sites-available/$2.conf
NGINX=/etc/apache2/sites-available/$2.conf

# $1 is the user $2 is the domain
### root privileges check
if [[ $EUID -ne 0 ]]; then
    echo "mksite: This script must be run as root. Aborting."
    echo
    exit 1
fi
### parameters count check (2)
if [ $# -ne 2 ]; then
    echo "mksite: Missing parameter(s). Usage: mksite [user] [FQDN]"
    echo "                            Example: mksite newuser newsite.co.uk"
    echo
    exit 1
fi
### existing apache2 .conf file check
if [ -f "$APACHE" ]; then
    echo "mksite:  file /etc/apache/sites-available/"$2".conf already exists. Aborting."
    echo
    exit 1
fi

### existing nginx.conf file check
if [ -f "$NGINX" ]; then
    echo "mksite:  file /etc/nginx/sites-available/"$2".conf already exists. Aborting."
    echo
    exit 1
fi

PWD="$(pwgen -B 12 1)"
#user jazz:
adduser $1 --disabled-password --gecos "" 
echo $1:$PWD | chpasswd

# Apache
if [ -f "/etc/apache2/sites-available/TEMPLATE" ]; then
  cp -v /etc/apache2/sites-available/TEMPLATE /etc/apache2/sites-available/"$2".conf
#sed domain and user 
  sed -i "s/DOMAINU/$1/g" /etc/apache2/sites-available/"$2".conf
  sed -i "s/DOMAIN/$2/g" /etc/apache2/sites-available/"$2".conf
  sed -i "s/USER/$1/g" /etc/apache2/sites-available/"$2".conf
  ln -s /etc/apache2/sites-available/"$2".conf /etc/apache2/sites-enabled/
  apache2ctl -t && apache2ctl restart
else 
  echo "No TEMPLATE found, aborting"
  exit 1
fi

# Nginx
if [ -f "$NGINX" ]; then
cp -v /etc/nginx/sites-available/TEMPLATE /etc/nginx/sites-available/"$2"
##sed the file:
sed -i "s/DOMAINU/$1/g" /etc/nginx/sites-available/$2
sed -i "s/DOMAIN/$2/g" /etc/nginx/sites-available/$2
ln -s /etc/nginx/sites-available/$2 /etc/nginx/sites-enabled/$2
nginx -t && nginx -s reload

apache2ctl -S | grep $2
echo $1 password is: "$PWD"
