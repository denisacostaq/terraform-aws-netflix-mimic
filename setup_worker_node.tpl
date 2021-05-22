#!/bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
sudo mkdir -p /var/www/html/${worker_name}
echo "<h1>${worker_name} running in ${az}</h1>" | sudo tee /var/www/html/${worker_name}/index.html
