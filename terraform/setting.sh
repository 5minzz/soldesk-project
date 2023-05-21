#!/bin/bash
sudo amazon-linux-extras install epel -y
sudo yum install stress -y
sudo yum install wget -y  
sudo yum install httpd -y
sudo amazon-linux-extras install php7.4 -y
sudo yum install php-xml -y
sudo yum install mariadb -y
sudo wget -P /var/www/html https://getcomposer.org/installer
sudo php /var/www/html/installer 
sudo mv /composer.phar /usr/local/bin/composer
sudo ln -s /usr/local/bin/composer /usr/bin/composer
sudo composer require aws/aws-sdk-php
sudo mv /vendor /var/www/html/
sudo systemctl start httpd.service
sudo systemctl enable httpd.service
sudo sed -i -e 's/post_max_size = 8M/post_max_size = 1024M/g' /etc/php.ini
sudo sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 1024M/g' /etc/php.ini
sudo systemctl restart php-fpm
sudo systemctl restart httpd.service
sudo aws configure set region ap-northeast-2
sudo aws configure set aws_access_key_id 'access_key' 
sudo aws configure set aws_secret_access_key 'secret_key'
sudo aws s3 cp s3://55mintest2/index.html /var/www/html/
sudo aws s3 cp s3://55mintest2/proj3-4.tar /var/www/html/
sudo aws s3 cp s3://55mintest2/vendor.tar /var/www/html/
sudo aws s3 cp s3://55mintest2/dist.tar /var/www/html/
sudo tar -xf /var/www/html/proj3-4.tar -C /var/www/html/.
sudo tar -xf /var/www/html/vendor.tar -C /var/www/html/.
sudo tar -xf /var/www/html/dist.tar -C /var/www/html/.