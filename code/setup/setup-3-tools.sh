#!/bin/bash
sudo apt-get update

# Install packages to allow apt to use a repository over HTTPS:
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Add Docker’s official GPG key:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# set up the stable repository.
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# install docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-compose

# give ubuntu permissions to execute docker
sudo usermod -aG docker $(whoami)
# log out
exit
# log back in

# make sure docker is working
docker run hello-world

# Add hosts entries (mocking DNS) - put relevant IPs here
echo "
192.168.45.130 pktools pen-kafka-tools
192.168.45.131 pk1 pzk1 pen-kafka1 pen-zookeeper1
192.168.45.132 pk2 pzk2 pen-kafka2 pen-zookeeper2
192.168.45.133 pk3 pzk3 pen-kafka3 pen-zookeeper3" | sudo tee --append /etc/hosts
