#!/bin/bash
# Software installataion script version 1.0
# set -eu -o pipefail # fail on error and report it, debug all lines

# To check whether the user have sudo previlege
sudo -n true
test $? -eq 0 || exit 1 "you should have sudo privilege to run this script"

echo "==========================="
echo "Software Setup"
echo "==========================="

# update and upgrade packages
sudo apt update && sudo apt upgrade -y

# Some of the common-dependencies
sudo apt install wget curl dirmngr gnupg apt-transport-https ca-certificates software-properties-common lsb-release -y

# Import repository for vscode
wget -O- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor | sudo tee /usr/share/keyrings/vscode.gpg
echo deb [arch=amd64 signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/vscode stable main | sudo tee /etc/apt/sources.list.d/vscode.list

# Import repository for elastic-search
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic.gpg
echo "deb [signed-by=/usr/share/keyrings/elastic.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list

# Import repository for MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list

# Importing repository for Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Importing repository for cassandra
echo "deb http://www.apache.org/dist/cassandra/debian 40x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
wget -q -O - https://www.apache.org/dist/cassandra/KEYS | sudo tee /etc/apt/trusted.gpg.d/cassandra.asc

# Import repository for mongodb dependency library libssl1.1
echo "deb http://security.ubuntu.com/ubuntu focal-security main" | sudo tee /etc/apt/sources.list.d/focal-security.list

# update and upgrade packages
sudo apt update

# REDIS
sudo apt install redis-server -y

# MYSQL
sudo apt install mysql-server -y

# DOCKER
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
sudo docker run hello-world # Testing the docker installation

# ELASTIC-SEARCH
sudo apt install elasticsearch -y

# VSCODE
sudo apt install code -y

# MONGODB
sudo apt-get install libssl1.1 -y
sudo rm /etc/apt/sources.list.d/focal-security.list
sudo apt-get install mongodb-org -y
systemctl start mongod
systemctl enable mongod

# MongoDB Compass
wget https://downloads.mongodb.com/compass/mongodb-compass_1.34.1_amd64.deb
sudo dpkg -i mongodb-compass_1.34.1_amd64.deb

# CASSANDRA
sudo apt install cassandra -y

# KAFKA
sudo apt install default-jdk -y # Install java for kafka
wget https://downloads.apache.org/kafka/3.3.1/kafka_2.12-3.3.1.tgz # Downloading kafka
tar xzf kafka_2.12-3.3.1.tgz # Extract
sudo mv kafka_2.12-3.3.1.tgz /usr/local/kafka # Move to the desired folder
cd /etc/systemd/system/ # open the path to place the files

# Zookeeper service file
sudo tee -a zookeeper.service <<EOF
[Unit]
Description=Apache Zookeeper server
Documentation=http://zookeeper.apache.org
Requires=network.target remote-fs.target
After=network.target remote-fs.target

[Service]
Type=simple
ExecStart=/usr/local/kafka/bin/zookeeper-server-start.sh /usr/local/kafka/config/zookeeper.properties
ExecStop=/usr/local/kafka/bin/zookeeper-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

# Kafka service file
sudo tee -a kafka.service <<EOF
[Unit]
Description=Apache Kafka Server
Documentation=http://kafka.apache.org/documentation.html
Requires=zookeeper.service

[Service]
Type=simple
Environment="JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"
ExecStart=/usr/local/kafka/bin/kafka-server-start.sh /usr/local/kafka/config/server.properties
ExecStop=/usr/local/kafka/bin/kafka-server-stop.sh

[Install]
WantedBy=multi-user.target
EOF

cd # Again moves to home direcotry

# Reload daemon
sudo systemctl daemon-reload 

# Start the services
sudo systemctl start zookeeper 
sudo systemctl start kafka