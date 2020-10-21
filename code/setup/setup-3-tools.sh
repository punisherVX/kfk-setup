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
10.29.75.150 tbd-lago-tools tltools
10.29.75.151 tbd-kafka1 tkfk1
10.29.75.151 tbd-zookeeper1 tzk1
10.29.75.152 tbd-kafka2 tkfk2
10.29.75.152 tbd-zookeeper2 tzk2
10.29.75.153 tbd-kafka3 tkfk3
10.29.75.153 tbd-zookeeper3 tzk3
" | sudo tee --append /etc/hosts


mkdir tools

# Create the docker compose file for ZooNavigator
echo "
version: '2'

services:
  # https://github.com/elkozmon/zoonavigator
  web:
    image: elkozmon/zoonavigator-web:latest
    container_name: zoonavigator-web
    network_mode: host
    environment:
      API_HOST: 'localhost'
      API_PORT: 9001
      SERVER_HTTP_PORT: 8001
    depends_on:
     - api
    restart: always
  api:
    image: elkozmon/zoonavigator-api:latest
    container_name: zoonavigator-api
    network_mode: host
    environment:
      SERVER_HTTP_PORT: 9001
    restart: always
" | tee --append tools/zoonavigator-docker-compose.yml

# Create the docker compose file for Kafka Manager
echo "
version: '2'

services:
  # https://github.com/yahoo/kafka-manager
  kafka-manager:
    image: qnib/plain-kafka-manager
    network_mode: host
    environment:
      ZOOKEEPER_HOSTS: "tbd-zookeeper1:2181,tbd-zookeeper2:2181,tbd-zookeeper3:2181"
      APPLICATION_SECRET: change_me_please
    restart: always
" |tee --append tools/kafka-manager-docker-compose.yml


# Create the docker compose file for Kafka Topics UI
echo "
version: '2'

services:
  # https://github.com/confluentinc/schema-registry
  confluent-schema-registry:
    image: confluentinc/cp-schema-registry:3.2.1
    network_mode: host
    environment:
      SCHEMA_REGISTRY_KAFKASTORE_CONNECTION_URL: tbd-zookeeper1:2181,tbd-zookeeper2:2181,tbd-zookeeper3:2181/kafka
      SCHEMA_REGISTRY_LISTENERS: http://0.0.0.0:8081
      # please replace this setting by the IP of your web tools server
      SCHEMA_REGISTRY_HOST_NAME: 'tltools'
    restart: always

  # https://github.com/confluentinc/kafka-rest
  confluent-rest-proxy:
    image: confluentinc/cp-kafka-rest:3.2.1
    network_mode: host
    environment:
      KAFKA_REST_BOOTSTRAP_SERVERS: tbd-kafka1:9092,tbd-kafka2:9092,tbd-kafka3:9092
      KAFKA_REST_ZOOKEEPER_CONNECT: tbd-zookeeper1:2181,tbd-zookeeper2:2181,tbd-zookeeper3:2181/kafka
      KAFKA_REST_LISTENERS: http://0.0.0.0:8082/
      KAFKA_REST_SCHEMA_REGISTRY_URL: http://localhost:8081/
      # please replace this setting by the IP of your web tools server
      KAFKA_REST_HOST_NAME: 'tltools'
    depends_on:
      - confluent-schema-registry
    restart: always

  # https://github.com/Landoop/kafka-topics-ui
  kafka-topics-ui:
    image: landoop/kafka-topics-ui:0.9.2
    network_mode: host
    environment:
      KAFKA_REST_PROXY_URL: http://localhost:8082
      PROXY: 'TRUE'
    depends_on:
      - confluent-rest-proxy
    restart: always
" | tee --append tools/kafka-topics-ui-docker-compose.yml

# make sure you can access the zookeeper endpoints
nc -vz tbd-zookeeper1 2181
nc -vz tbd-zookeeper2 2181
nc -vz tbd-zookeeper3 2181

# make sure you can access the kafka endpoints
nc -vz tbd-kafka1 9092
nc -vz tbd-kafka2 9092
nc -vz tbd-kafka3 9092

# launch the containers
# Zoo Navigator runs on port 8001
# Kafka Manager runs on port 9000
# Kafka Topics UI runs on port 8000
docker-compose -f tools/kafka-manager-docker-compose.yml up -d
docker-compose -f tools/kafka-topics-ui-docker-compose.yml up -d
docker-compose -f tools/zoonavigator-docker-compose.yml up -d
