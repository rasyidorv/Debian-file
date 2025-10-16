#!/bin/bash 

n="nano" 

apt update
apt install telnet -y 
apt install postfix dovecot-pop3d dovecot-imapd -y

cat <<QW >>/etc/postfix/main.cf

home_mailbox = Maildir/

QW

maildirmake.dovecot /etc/skel/Maildir

$n /etc/dovecot/dovecot.conf

$n /etc/dovecot/conf.d/10-auth.conf

$n /etc/dovecot/conf.d/10-mail.conf

systemctl restart postfix dovecot

apt install apache2 mariadb-server roundcube -y

cd /etc/apache2/sites-available

cp 000-default.conf roundcube.conf

$n roundcube.conf

a2ensite roundcube.conf && a2dissite 000-default.conf

systemctl reload apache2 

cd /etc/roundcube

$n config.inc.php

systemctl restart apache2 postfix dovecot 

