# ft_server :whale:

**Codam [42 Network] project**: set up a web server with **Nginx** in a single **Docker** container.

__Project requirements__:
 - The container OS must be Debian Buster.
 - The web server must be able to run **several services** at the same time. These services will be a **WordPress** website, **phpMyAdmin** and **MySQL**. The SQL database should work with WordPress and phpMyAdmin.
 - The server should be able to use the **SSL protocol** and redirect to the correct website (http to https).
 - The server is running with an **autoindex** that must be able to be disabled.

__Skills__:
- System and network administration
- Rigor

[Read the full subject](https://github.com/nvanwinden/ft_server/blob/master/en.subject.pdf).

## Instructions :clipboard:

### Clone repo
`git clone https://github.com/nvanwinden/ft_server.git`

### Build Docker image
`docker build -t ft_server .`

| Options |  |
|--|--|
| `-t`   | name the image |
| `.`   | current directory |

### Run Docker container
`docker run --name ft_server -it -p 80:80 -p 443:443 ft_server`

| Options |  |
|--|--|
| `--name` | specify container name |
| `-it` | creating an interactive bash shell in the container |
| `-p` | publish and map one or more ports |

### Folder structure
```markdown
├── srcs
│   ├── autoindex.sh
│   ├── config.inc.php
│   ├── nginx.conf
├── Dockerfile
├── en.subject.pdf
├── README.md
```

## Basic tests :test_tube:

### Wordpress website

> https://localhost/

Wordpress is installed in the default document root of Nginx and the installation process is handled by WP-CLI.

### Wordpress admin dashboard
> https://localhost/wp-admin<br>
> Username: wpuser<br>
> Password: password

You can add pages, create new users, upload files, add posts, etc.
By default, Nginx has a limit of 1mb on file uploads. In the Nginx config file the limit size for file uploads is increased to 20mb to support high res (4k images).

### phpMyAdmin
> https://localhost/phpmyadmin/<br>
> Username: dbuser<br>
> Password: password

To check if the SQL database is configured properly, your new pages, users, uploads and posts should all be visible in phpMyAdmin.

### SSL protocol

Any HTTP request coming in at port 80 is redirected to port 443. 
**http**://localhost/phpmyadmin/ should redirect to **https**://localhost/phpmyadmin/
 
### Autoindex
Autoindex is enabled by default. This can be verified by visiting https://localhost/wp-includes/ after running the container. The directory listing should be visible in your browser.  To disable autoindex, simply run the following command `docker exec -it ft_server /bin/bash ./autoindex.sh off`. This will execute the autoindex.sh script in the container root.

## Useful Docker commands :keyboard:

| Command | Description |
|--|--|
| `docker stop [container name]` | stop container |
| `docker start [container name]`   | start container |
| `docker ps`   | show running containers |
| `docker ps -a` | show all containers |
| `docker system prune -a` | remove all unused containers, networks, images and optionally, volumes.
| `docker logs [container name]` | fetch the logs of a container |
| `docker images` | list images |
| `docker container ls -a` | list containers |
| `docker exec -it [container name] bash` | run a command in a running container

<details>
<summary>Notes Dockerfile :notebook:</summary>

## Notes Dockerfile

`FROM  debian:buster`
`FROM` must be the first instruction in a Dockerfile and specifies the underlying OS architecture that you're using to build the image.

`LABEL  maintainer="Nilo  van  Winden  <nvan-win@student.codam.nl>"`
The `LABEL` instruction adds metadata to an image.  The metadata can be viewed with the command `docker inspect [container name]` after the image is build.

`RUN  apt  update; \`
`apt  upgrade  -y;`
**apt** [Advanced Packaging Tool] is a command line utility for installing, updating, removing and managing packages on Ubuntu, Debian, and related Linux distributions.
Difference between `apt` and `apt-get`: https://itsfoss.com/apt-vs-apt-get-difference/

`RUN  apt  install`
**Nginx** is a web server that stores and delivers the content for a website to clients that request it.
**MariaDB (fork of MySQL)** is one of the most popular open-source SQL relational databases management systems.
**PHP-FPM (FastCGI Process Manager)** is a web tool used to speed up the performance of a website.
**wget** is a command line utility for downloading files from the internet.
**Sendmail** is an SMTP-based (Simple Mail Transfer Protocol) mail transfer agent.

`RUN  sendmailconfig;`
[sendmailconfig](https://manpages.ubuntu.com/manpages/xenial/man8/sendmailconfig.8.html) is used to simplify the configuration of sendmail for use on Debian systems.

`COPY  /srcs/nginx.conf  /etc/nginx/sites-available/localhost`
`RUN  ln  -s  /etc/nginx/sites-available/localhost  /etc/nginx/sites-enabled/localhost`
Copy Nginx config file to sites-available and create symlink to the file in sites-enabled.
```
RUN  openssl  req  -x509  -days  365  -newkey  rsa:2048  -nodes  -sha256  \
-out  /etc/ssl/certs/nginx-selfsigned.crt  \
-keyout  /etc/ssl/private/nginx-selfsigned.key  \
-subj  "/C=NL/ST=NH/L=Amsterdam/O=Codam/CN=localhost";  \
chmod  775  /etc/ssl/private/nginx-selfsigned.key;  \
chmod  775  /etc/ssl/certs/nginx-selfsigned.crt
```
**SSL**  (Secure  Sockets  Layer) is  the  protocol  for  web  browsers  and  servers  that  allows  for  the  authentication,  encryption  and  decryption  of  data  sent  over  the  internet.

`openssl`: basic  command  line  tool  for  creating  and  managing  OpenSSL  certificates,  keys,  and  other  files. It  creates  both  your  private  key  and  certificate  signing  request  (csr)  and  saves  them  to  2  files
-  your_common_name.key
-  you_common_name.csr

`req -x509`: specifies we want to use X.509 certificate signing request (CSR) management. The "X.509" is a public key infrastructure standard that SSL and TLS adhere for key and certificate management.

`-days  365` This  option  sets  the  length  of  time  that  the  certificate  will  be  considered  valid. 

`newkey rsa:2048`: we want to generate a new certificate and a new key at the same time. We did not create the key that is required to sign the certificate in a previous step, so we need to create it along with the certificate. The `rsa:2048` portion tells it to make an RSA key that is 2048 bits long.

`-nodes` tells  OpenSSL  to  skip  the  option  to  secure  our  certificate  with  a  passphrase.  We  need  Nginx  to  be  able  to  read  the  file,  without  user  intervention,  when  the  server  starts  up.  A  passphrase  would  prevent  this  from  happening  because  we  would  have  to  enter  it  after  every  restart.

`-sha256` Secure  Hashing  Algorithm.  [SHA256](https://comodosslstore.com/resources/what-is-a-sha256-ssl-certificate/)  is  the  latest  hashing  algorithm  of  the  SHA  (secure  hashing  algorithm)  family  with  a  256-bit  length. 

`-out`  This  tells  OpenSSL  where  to  place  the  certificate  that  we  are  creating.

`-keyout` tells  OpenSSL  where  to  place  the  generated  private  key  file  that  we  are  creating.

`-subj`  Non-interactively  answer  the  CSR  (Certificate  Signing  Request)  information  prompt.

`chmod 775` sets permissions so that (U)ser / owner can read, can write and can execute. (G)roup can read, can write and can execute. (O)thers can read, can't write and can execute.

[Source](https://gist.github.com/dryliketoast/5c62027480e21db95703219689de1793)

```
RUN  wget  https://files.phpmyadmin.net/phpMyAdmin/4.9.7/phpMyAdmin-4.9.7-all-languages.tar.gz;  \
tar  -xzvf  phpMyAdmin-4.9.7-all-languages.tar.gz  -C  /var/www/html;
```

**phpMyAdmin**  is  a  free  software  tool  written  in  PHP,  intended  to  handle  the  administration  of  MySQL  over  the  Web.  phpMyAdmin  supports  a  wide  range  of  operations  on  MySQL  and  MariaDB.

`x`  extract  files  from  an  archive.
`z`  compress  the  resulting  archive  with  gzip(1).  In  extract  or  list  modes,  this  option  is  ignored.
`v`  verbose,  shows  the  progress  on  the  screen
`f`  tar  archive  name

`RUN  chmod  660  /var/www/html/phpmyadmin/config.inc.php`
`chmod 660` sets permissions so that, (U)ser / owner can read, can write and can't execute. (G)roup can read, can write and can't execute. (O)thers can't read, can't write and can't execute.

`mysql  <  /var/www/html/phpmyadmin/sql/create_tables.sql;`
[import sql/create_tables.sql](https://docs.phpmyadmin.net/nl/latest/setup.html) to create new tables

`wget  -P  var/www/html/  https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar;`
**WP-CLI** is a tool to manage WordPress via the command line. It's used for installing and setting up a WordPress website, changing its options, administering users, etc.
`-P` set directory for WordPress client.

`mv  var/www/html/wp-cli.phar  /usr/local/bin/wp;`
Move to bin so it's available as a wp command.

`wp  core  download  --allow-root;`
Download the latest version of WordPress into the current directory. Runs the standard WordPress installation process.

`echo  "USE  wordpress;  UPDATE  wp_options  SET  option_value='https://localhost/'  WHERE  option_name='siteurl'  OR  option_name='home';"  |  mysql  -u  root`
`wp_options`:  the  table  where  your  URL  is  saved
`SET` : wp  option  to  set  the  URL
`WHERE` : tells  the  program  the  name  of  the  host  where  the  MySQL  server  is  running
[Source](https://www.ostraining.com/blog/wordpress/site-url-and-home-url-wordpress/)

`RUN  chown  -R  www-data:www-data  /var/www/html`
Give  ownership  to  web root.
`chown`  can  change  owner  and  group  assignments. The  syntax  is  `chown  owner:group  filename`,  so  to  change  the  owner  of  file1  to  user1  and  the  group  to  family  you  would  enter  `chown  user1:family  file1`
`www-data`  is  the  user  that  web  servers  use  by  default  for  normal  operation.
The  web  server  process  can  access  any  file  that  www-data  can  access.
`-R`  change  the  user  ID  and/or  the  group  ID  for  the  file  hierarchies rooted  in  the  directories  instead  of  just  the  files  themselves.

```
CMD  service  nginx  start;  \
service  mysql  start;  \
service  php7.3-fpm  start;  \
service  sendmail  start;  \
bash;  \
tail  -f  /var/log/nginx/access.log
```
Starting  services.
`CMD`  specifies  what  command  to  run  within  the  container;  it's  a  constant  loop.
`tail`  displays  the  last  part  of  a  file.
`-f`  keeps  the  program  running,  causes  tail  to  not  stop  when  end  of  file  is  reached  but  rather  to  wait  for  additional  data  to  be  appended  to  the  input.
`/var/log/nginx/access.log`  makes  it  so  you  can  see  docker  logs. An alternative  is  to  use  `service  nginx  start  ;  tail  -f  dev/null`.
`dev/null`  is  present  on  every  linux  system,  you  write  to  it  and  whatever  you  write  to  /dev/null  will  be  discarded,  forgotten  into  the  void,  It's  known  as  the  null  device  in  a  UNIX  system.
</details>


<details>
<summary>Notes nginx.conf :notebook:</summary>

## Notes nginx.conf

A **server block** is a subset of Nginx’s configuration that defines a virtual server used to handle requests of a defined type. Administrators often configure multiple server blocks and decide which block should handle which connection based on the requested domain name, port, and IP address.
```
server {
	listen 80;
```
 The listen directive typically defines which IP address and port the server block will respond to.

	    listen [::]:80;

IPv6 addresses (0.7.36) are specified in square brackets.

	    server_name localhost;

Server names are defined using the server_name directive and determine which server block is used for a given request.

	    return 301 https://$server_name$request_uri;

[Redirect](https://www.hostinger.com/tutorials/nginx-redirect/) all requests coming from HTTP (port 80) to HTTPS (port 443).

    }

```
server {

	listen 443 ssl;
	listen [::]:443 ssl;
	ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
	ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
```

    root /var/www/html;
The root directive specifies the root directory that will be used to search for a file.

    client_max_body_size 20m;
By default, Nginx has a limit of 1MB on file uploads. Limit increased to 20MB to support high res (4K) images.

`index index.php index.html index.htm index.nginx-debian.html;`
If multiple files are specified for the index directive, NGINX will process the list in order and fulfill the request with the first file that exists. If index.html doesn’t exist, then index.htm will be used. If neither exists, a 404 message will be sent.
```
server_name localhost;
	location / {
		autoindex on;
		try_files $uri $uri/ =404;
```
Using try_files means that you can test a sequence. If $uri doesn’t exist, try $uri/, if that doesn’t exist try a fallback location.
```
	}

	location ~ \.php$ {
		include snippets/fastcgi-php.conf;
		fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
	}
}
``` 
Handle PHP requests.

</details>
