#*****************************************************************#
#Rtcamp: Assignment No-2:-Shell Scripting 
# Author:- Kishor S Dhanawade
# Email Id- kishorsd21@gmail.com
#*****************************************************************#

#!/bin/sh -e

check_host_pkgs () 
{
	
	pkg="mysql-server"
	check_dpkg
	pkg="php5"
	check_dpkg
	pkg="php5-mysql"
	check_dpkg
	pkg="nginx"
	check_dpkg


	if [ "${deb_pkgs}" ] ; then
		ping -c1 www.google.com | grep ttl >/dev/null 2>&1 || network_down
		echo "Installing: ${deb_pkgs}"
		sudo apt-get update
		sudo apt-get -y install ${deb_pkgs}
		sudo apt-get autoclean
	fi
}

network_down()
{
	echo "Network down. Please check your internet connection... "
	exit
}

check_dpkg () 
{
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}$" >/dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}

enter_domain_name()
{
	echo -n "Please Enter Domain Name :- "
	read domain_name
	sudo sed -i "1i127.0.0.1  $domain_name" /etc/hosts	
	echo "$domain_name entry created in /etc/hosts..."
}

nginx_conf()
{
	sudo chown $HOSTNAME:$HOSTNAME /etc/nginx/sites-available /etc/nginx/sites-enabled
	sudo echo "  server {
    					listen    80;
    					server_name    $domain_name;
    					access_log    /var/log/nginx/$domain_name.access.log;
   					error_log    /var/log/nginx/$domain_name.error.log;

				      location / {
        							root    /var/www/$domain_name;
        							index    index.php index.html index.htm;
   						     }

    			location ~ \.php$ {
        						include /etc/nginx/fastcgi_params;
        						fastcgi_pass   127.0.0.1:9000;
       					 	fastcgi_index  index.php;
        						fastcgi_param  SCRIPT_FILENAME /var/www/$domain_name\$fastcgi_script_name;
    						}
				} " > /etc/nginx/sites-available/${domain_name}.conf
	sudo ln -s /etc/nginx/sites-available/${domain_name}.conf /etc/nginx/sites-enabled/${domain_name}.conf
	sudo chown root /etc/nginx/sites-available /etc/nginx/sites-enabled
	sudo mkdir /var/www /var/www/$domain_name; 2> /dev/null
	echo "$domain_name nginx conf file created and linked"
}

wordpress()
{
	echo "Downloading latest version of Wordpress."
	cd /var/www/$domain_name/
	sudo wget http://wordpress.org/latest.tar.gz
	sudo tar -zxvf latest.tar.gz
	sudo rm latest.tar.gz

}

mysql()
{
	echo "Creating mysql database...."	
	echo -n "Please enter the mysql username :- "
	read username
	echo "Enter the name of the database :-"
	read db_name
	mysqladmin -u $username -p CREATE  $db_name
	if [ ! $? = 0 ]; then
		echo
		echo "Username/Password Incorrect.. Please try again"
		echo
		mysql
	else
	echo "$db_name created successfully..."
	fi
}

wpconfig()
{
	sudo cp /var/www/$domain_name/wordpress/wp-config-sample.php /var/www/$domain_name/wordpress/wp-config.php
	sudo sed -i 's/database_name_here/'$db_name'/g' /var/www/$domain_name/wordpress/wp-config.php
	sudo sed -i 's/username_here/'$username'/g' /var/www/$domain_name/wordpress/wp-config.php
	sudo sed -i 's/password_here/'$password'/g' /var/www/$domain_name/wordpress/wp-config.php
	echo "wp-config.php file created with proper DB configuration."	
}

check_host_pkgs
enter_domain_name
nginx_conf
wordpress
mysql
wpconfig

sudo /etc/init.d/nginx restart 1> /dev/null
sudo /etc/init.d/php5-fpm restart 1> /dev/null

echo "Script execution completed succesfully......"
echo "Please enter the $domain_name into your browser."

