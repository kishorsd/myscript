#*****************************************************************#
#Rtcamp: Assignment No-2:-Shell Scripting 
# Author:- Kishor S Dhanawade
# Email Id- kishorsd21@gmail.com
#*****************************************************************#

#!/bin/sh -e


#This function will call check package function and if package is not already installed then this will 
# check the network connection and then update the system and uninstalled package will install from internet.
check_host_pkgs () 
{
	if [ $(id -u) -eq 0 ];then         #check for root user
		pkg="mysql-server"
		check_dpkg
		pkg="php5-fpm"
		check_dpkg
		pkg="php5-mysql"
		check_dpkg
		pkg="nginx"
		check_dpkg


		if [ "${deb_pkgs}" ] ; then
			ping -c3 www.google.com | grep ttl >/dev/null 2>&1 || network_down
			sudo apt-get update
			echo "Installing: ${deb_pkgs}"
			sudo apt-get -y install ${deb_pkgs}  --no-install-recommends
			sudo apt-get autoclean
		fi
	else
		echo "You need to be root..."
		exit
	fi	
}

#If your system is not connected with internet then then this function will called. 
network_down()
{
	echo "Network down. Please check your internet connection... "
	exit
}

#following function is to check whether the package is already installed or not.
check_dpkg () 
{
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}$" > /dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}

#Function will ask domain name
#/etc/hosts configuration file will update with this domain name.
enter_domain_name()
{
	echo -n "Please Enter Domain Name :- "
	read domain_name                                       
	grep -i "$domain_name" /etc/hosts > /dev/null              #check for domain name whether it is already taken
	if [ $? -eq 0 ]; then
		{
			echo "Domain name already exists... Please enter another domain name..."
		}
	else
		{
			sudo sed -i "1i127.0.0.1  $domain_name" /etc/hosts    #insert domain name at 1stline in /etc/hosts
			echo "$domain_name entry created in /etc/hosts"
		}
	fi
}


#function creates nginx configuration file
#Configuration file is created and updated in the /etc/nginx/sites-available folder.
#This file is sym-linked in /etc/nginx/sites-enabled.
# Logs are created in /var/log/nginx
#create a directory /var/www for wordpress zip.
nginx_conf()
{
	
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
	sudo ln -s /etc/nginx/sites-available/${domain_name}.conf /etc/nginx/sites-enabled/${domain_name}.conf  #symlink
	sudo mkdir /var/www /var/www/$domain_name; 2> /dev/null    #make directory
	echo "$domain_name nginx conf file created and linked"
}


#This function downloads WordPress latest version from http://wordpress.org/latest.tar.gz.
#Extract tar.gz to /var/www
wordpress()
{
	echo "Downloading latest version of Wordpress."
	cd /var/www/$domain_name/
	sudo wget http://wordpress.org/latest.tar.gz   #wget to download latest.tar.gz
	sudo tar -zxvf latest.tar.gz                  #extract file to /var/www/domain_name/
	sudo rm latest.tar.gz                         #remove unwanted file.

}


#This function creates mysql database
#Ask to enter username and password to user
mysql()
{
	echo "Creating mysql database...."	
	echo -n "Please enter the mysql username :- "                  #-n to read username on same line
	read username
	echo -n "Enter the name of the database :-"
	read db_name
	mysqladmin -u $username -p CREATE  $db_name                   #-u for username, -p for password
	if [ ! $? = 0 ]; then                                        #to check exit status of previous command
		echo
		echo "Username/Password Incorrect.. Please try again"
		echo
		mysql
	else
	echo "$db_name created successfully..."
	fi
}

#copy wp-config-sample.php from wordpress as wp-config.php
#Edit wp-config.php file as per the domain name ,username and password for DB configuration
wpconfig()
{
	sudo cp /var/www/$domain_name/wordpress/wp-config-sample.php /var/www/$domain_name/wordpress/wp-config.php
	sudo sed -i 's/database_name_here/'$db_name'/g' /var/www/$domain_name/wordpress/wp-config.php  #substitute sed command to replace the database name
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

sudo /etc/init.d/nginx restart 1> /dev/null       #restart the nginx
sudo /etc/init.d/php5-fpm restart 1> /dev/null    #restart php-fpm

echo "Script execution completed succesfully......"
echo "Please enter the $domain_name into your browser."

