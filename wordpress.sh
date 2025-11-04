#!/bin/bash
# =====================================================
#  Auto Install WordPress on Debian 11 (Apache2 + PHP + MariaDB)
#  No Domain Version (Access via IP)
#  Author : RASYID (dibantu oleh ChatGPT)
# =====================================================

# === Variabel yang bisa diubah ===
DB_NAME="wordpress_db"
DB_USER="wordpress_user"
DB_PASS="passwordku123"   # ubah ke password kuat
WEB_ROOT="/var/www/html/wordpress"
PHP_VERSION="7.4"
# ================================

echo "=== [1/8] Update & Upgrade Sistem ==="
apt update -y && apt upgrade -y
apt install -y nano wget unzip curl lsb-release ca-certificates apt-transport-https software-properties-common

echo "=== [2/8] Install Apache2 ==="
apt install -y apache2
systemctl enable apache2
systemctl start apache2

echo "=== [3/8] Install PHP & Extensions ==="
apt install -y php php-mysql php-xml php-gd php-curl php-mbstring php-zip php-intl

PHP_INI="/etc/php/${PHP_VERSION}/apache2/php.ini"
if [ -f "$PHP_INI" ]; then
  sed -i 's/^max_execution_time = .*/max_execution_time = 300/' $PHP_INI
  sed -i 's/^memory_limit = .*/memory_limit = 512M/' $PHP_INI
  sed -i 's/^post_max_size = .*/post_max_size = 128M/' $PHP_INI
  sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 128M/' $PHP_INI
  systemctl restart apache2
else
  echo "⚠️ File php.ini tidak ditemukan di $PHP_INI"
fi

echo "=== [4/8] Install MariaDB ==="
apt install -y mariadb-server mariadb-client
systemctl enable mariadb
systemctl start mariadb

echo "=== [5/8] Buat Database WordPress ==="
mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE ${DB_NAME};
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "Database & user dibuat:"
echo "  DB Name : ${DB_NAME}"
echo "  DB User : ${DB_USER}"
echo "  DB Pass : ${DB_PASS}"

echo "=== [6/8] Download dan Konfigurasi WordPress ==="
cd /var/www/html/
wget https://wordpress.org/latest.zip
unzip -o latest.zip
rm -f latest.zip
mv wordpress ${WEB_ROOT}
cd ${WEB_ROOT}
cp wp-config-sample.php wp-config.php

# Konfigurasi wp-config.php
sed -i "s/database_name_here/${DB_NAME}/" wp-config.php
sed -i "s/username_here/${DB_USER}/" wp-config.php
sed -i "s/password_here/${DB_PASS}/" wp-config.php

chown -R www-data:www-data ${WEB_ROOT}
chmod -R 755 ${WEB_ROOT}

echo "=== [7/8] Konfigurasi Apache ==="
cat > /etc/apache2/sites-available/wordpress.conf <<EOF
<VirtualHost *:80>
    ServerAdmin admin@localhost
    DocumentRoot ${WEB_ROOT}
    <Directory ${WEB_ROOT}>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/wordpress_error.log
    CustomLog \${APACHE_LOG_DIR}/wordpress_access.log combined
</VirtualHost>
EOF

a2ensite wordpress.conf
a2dissite 000-default.conf
a2enmod rewrite
systemctl reload apache2

echo "=== [8/8] Instalasi Selesai ==="
IP=$(hostname -I | awk '{if (NF>=2) print $2; else print $1}')
echo "===================================================="
echo "WordPress berhasil diinstal!"
echo "Akses via browser: http://${IP}/"
echo ""
echo "Database:"
echo "  Nama     : ${DB_NAME}"
echo "  User     : ${DB_USER}"
echo "  Password : ${DB_PASS}"
echo "===================================================="
