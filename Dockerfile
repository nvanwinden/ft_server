# **************************************************************************** #
#                                                                              #
#                                                         ::::::::             #
#    Dockerfile                                         :+:    :+:             #
#                                                      +:+                     #
#    By: nvan-win <nvan-win@student.codam.nl>         +#+                      #
#                                                    +#+                       #
#    Created: 2020/11/29 09:58:17 by nvan-win      #+#    #+#                  #
#    Updated: 2022/10/09 11:35:48 by nvan-win      ########   odam.nl          #
#                                                                              #
# **************************************************************************** #

FROM	debian:buster

LABEL	maintainer="Nilo van Winden <nvan-win@student.codam.nl>"

RUN		apt update; \
		apt upgrade -y;

# install packages
RUN		apt install -y nginx; \
		apt install -y mariadb-server; \
		apt install -y php-fpm php-mysql php-mbstring; \
		apt install -y wget; \
		apt install -y sendmail

# config sendmail
RUN		sendmailconfig;

# modify nginx default config file and create symlink
COPY	/srcs/nginx.conf /etc/nginx/sites-available/localhost
RUN		ln -s /etc/nginx/sites-available/localhost /etc/nginx/sites-enabled/localhost

# SSL
RUN     openssl req -x509 -days 365 -newkey rsa:2048 -nodes -sha256 \
		-out /etc/ssl/certs/nginx-selfsigned.crt \
		-keyout	/etc/ssl/private/nginx-selfsigned.key \
		-subj "/C=NL/ST=NH/L=Amsterdam/O=Codam/CN=localhost"; \
		chmod 775 /etc/ssl/private/nginx-selfsigned.key; \
		chmod 775 /etc/ssl/certs/nginx-selfsigned.crt

# phpMyAdmin
RUN		wget https://files.phpmyadmin.net/phpMyAdmin/4.9.7/phpMyAdmin-4.9.7-all-languages.tar.gz; \
		tar -xzvf phpMyAdmin-4.9.7-all-languages.tar.gz -C /var/www/html; \
		mv /var/www/html/phpMyAdmin-4.9.7-all-languages /var/www/html/phpmyadmin; \
		rm phpMyAdmin-4.9.7-all-languages.tar.gz

# modify php default config file
COPY	./srcs/config.inc.php /var/www/html/phpmyadmin

RUN		chmod 660 /var/www/html/phpmyadmin/config.inc.php

# MySQL
RUN 	service mysql start; \
		mysql < /var/www/html/phpmyadmin/sql/create_tables.sql; \
		echo "CREATE DATABASE wordpress;" | mysql -u root; \
		echo "GRANT ALL ON *.* TO 'dbuser'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;" | mysql -u root; \
		echo "FLUSH PRIVILEGES;" | mysql -u root

# WordPress
RUN     service mysql start; \
        wget -P var/www/html/ https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar; \
        chmod +x var/www/html/wp-cli.phar; \
        mv var/www/html/wp-cli.phar /usr/local/bin/wp; \
        cd var/www/html/; \
        wp core download --allow-root; \
        wp config create --dbname=wordpress --dbuser=dbuser --dbpass=password --allow-root; \
        wp core install --url=localhost.com --title=ft_server --admin_user=wpuser --admin_password=password --admin_email=nvan-win@student.codam.nl --allow-root; \
		echo "USE wordpress; UPDATE wp_options SET option_value='https://localhost/' WHERE option_name='siteurl' OR option_name='home';" | mysql -u root

# change max upload file size
RUN		sed -i 's/upload_max_filesize = 2M/ upload_max_filesize = 20M/' /etc/php/7.3/fpm/php.ini; \
		sed -i 's/post_max_size = 8M/ post_max_size = 21M/' /etc/php/7.3/fpm/php.ini

# give ownership to webroot
RUN 	chown -R www-data:www-data /var/www/html

# autoindex
COPY 	./srcs/autoindex.sh /autoindex.sh
RUN		chmod +x /autoindex.sh

EXPOSE 	80 443

# starting services
CMD		service nginx start; \
		service mysql start; \
		service php7.3-fpm start; \
		service sendmail start; \
		bash; \
		tail -f /var/log/nginx/access.log