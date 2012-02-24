#!/bin/bash
 
DISTRO=$(lsb_release -i | awk '{print $3}')
 
function reset_root_mysql {
        killall -15 mysqld
        read -s -p 'Enter a new root password: ' MYSQL_ROOT_PASSWORD
        echo "UPDATE mysql.user SET Password=PASSWORD('$MYSQL_ROOT_PASSWORD') WHERE User='root';" | mysqld --bootstrap
}
 
if [[ ! ${DISTRO} =~ (Ubuntu) ]]; then
        reset_root_mysql
        service mysql start
else
        reset_root_mysql
fi