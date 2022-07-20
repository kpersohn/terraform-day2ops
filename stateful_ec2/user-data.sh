#! /bin/bash
set -eu
sudo yum install -y httpd
sudo systemctl start httpd
echo "<html><h1>Hello World!</h1></html>" > /var/www/html/index.html
