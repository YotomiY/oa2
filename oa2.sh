#!/bin/bash

# Update system
sudo apt update && sudo apt upgrade -y

# Install build-essential
sudo apt install build-essential -y

# Install Node.js and npm
sudo apt install nodejs npm -y

# Install PM2 globally
sudo npm install -g pm2

# Install MariaDB
sudo apt install mariadb-server -y

# Secure MariaDB Installation
sudo mysql_secure_installation

# Create a database and user
DB_NAME="oauths"
DB_USER="oauth"
DB_PASSWORD="oauth"

sudo mysql -u root -p -e "CREATE DATABASE ${DB_NAME};"
sudo mysql -u root -p -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
sudo mysql -u root -p -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
sudo mysql -u root -p -e "FLUSH PRIVILEGES;"

# Clone OA2 project from GitHub
REPO_URL="https://github.com/YotomiY/oauth.disc"
git clone ${REPO_URL}
PROJECT_DIR=$(basename ${REPO_URL} .git)
cd ${PROJECT_DIR}

# Install TypeScript globally
sudo npm install -g typescript

# Install dependencies and compile TypeScript in each folder
for dir in API Client Database Routine; do
  cd ${dir}
  npm install
  npx tsc
  cd ..
done

# Configure Database in Database/index.ts
DB_CONFIG="import * as sequelize from 'sequelize';

export const sequelizeInstance = new sequelize.Sequelize({
    host: 'localhost',
    username: '${DB_USER}',
    password: '${DB_PASSWORD}',
    database: '${DB_NAME}',
    port: 3306,
    dialect: 'mysql',
    define: {
        timestamps: true
    },
    logging: false,
    timezone: 'Europe/Paris',
    pool: {
        max: 50,
        min: 0,
        acquire: 30000,
        idle: 300000
    }
});

export { default as Auths } from './Auths';
export { default as Settings } from './Settings';
export { default as IPs } from './IPs';
export { default as Bots } from './Bots';
export { default as Admins } from './Admins';
export { default as LogsCommands } from './Logs.Commands';
export { default as LogsJoin } from './Logs.Join';
export { default as Blacklist } from './Blacklist';
export { default as Subscriptions } from './Subscriptions';"

echo "${DB_CONFIG}" > Database/index.ts

# Start API with PM2
cd API
pm2 start dist --name "API"

# Install Apache
sudo apt install apache2 -y

# Enable Apache modules
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_balancer
sudo a2enmod lbmethod_byrequests

# Configure Apache as a reverse proxy
APACHE_CONFIG="<VirtualHost *:80>
    ServerName your_domain.com

    ProxyRequests off
    ProxyPreserveHost on

    <Proxy *>
        Order deny,allow
        Allow from all
    </Proxy>

    ProxyPass / http://localhost:8080/
    ProxyPassReverse / http://localhost:8080/

    ProxyPass /api2 http://localhost:8081/
    ProxyPassReverse /api2 http://localhost:8081/
</VirtualHost>"

echo "${APACHE_CONFIG}" | sudo tee /etc/apache2/sites-available/node-app.conf

# Enable the Apache site
sudo a2ensite node-app

# Install phpMyAdmin
sudo apt install phpmyadmin php-mbstring php-zip php-gd php-json php-curl -y

# Include phpMyAdmin in Apache configuration
sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

# Restart Apache
sudo systemctl restart apache2

# Open firewall ports 80, 8080, and 8081
sudo ufw allow 80/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 8081/tcp
sudo ufw reload

echo "Setup is complete. Please configure your OAuth2 settings and start the Client manually."
