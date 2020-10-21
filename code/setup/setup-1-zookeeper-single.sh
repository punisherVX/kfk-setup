#!/bin/bash
# Packages
sudo apt update && sudo apt -y install wget ca-certificates zip net-tools vim nano tar netcat

# Java Open JDK 8
sudo apt -y install openjdk-8-jdk openjdk-8-jre
java -version

# Disable RAM Swap - can set to 0 on certain Linux distro
sudo sysctl vm.swappiness=1
echo 'vm.swappiness=1' | sudo tee --append /etc/sysctl.conf

# Add hosts entries (mocking DNS) - put relevant IPs here
echo "
10.29.75.151 tbd-kafka1 tkfk1
10.29.75.151 tbd-zookeeper1 tzk1
10.29.75.152 tbd-kafka2 tkfk2
10.29.75.152 tbd-zookeeper2 tzk2
10.29.75.153 tbd-kafka3 tkfk3
10.29.75.153 tbd-zookeeper3 tzk3
" | sudo tee --append /etc/hosts

# If needed, download Zookeeper and Kafka. Recommended is latest Kafka (2.6) and Scala 2.12
wget http://apache.mirror.digitalpacific.com.au/kafka/2.6.0/kafka_2.13-2.6.0.tgz
tar -zvxf kafka_2.13-2.6.0.tgz
rm kafka_2.13-2.6.0.tgz  # optional
sudo ln -s ~/kafka_2.13-2.6.0 /opt/kafka

# create data dictionary for zookeeper
sudo mkdir -p /data/zookeeper
sudo chown -R pensando:pensando /data/
# declare the server's identity
echo "3" > /data/zookeeper/myid

# Zookeeper quickstart
cp ../zookeeper/zookeeper.properties /opt/kafka/config/zookeeper.properties
/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
# binding to port 2181 -> you're good. Ctrl+C to exit

# Testing Zookeeper install
# Start Zookeeper in the background
/opt/kafka/bin/zookeeper-server-start.sh -daemon /opt/kafka/config/zookeeper.properties
/opt/kafka/bin/zookeeper-shell.sh localhost:2181
ls /
# Ctrl-C to exit

# demonstrate the use of a 4 letter word
echo "ruok" | nc localhost 2181 ; echo

# Install Zookeeper boot scripts
cp ../zookeeper/zookeeper_startup_systemV /etc/systemd/system/zookeeper.service
# enable the service and start it
sudo systemctl enable zookeeper.service
sudo systemctl start zookeeper.service
sudo systemctl status zookeeper.service

# stop zookeeper
sudo service zookeeper stop
# verify it's stopped - should get nothing back
nc -vz localhost 2181
# start zookeeper
sudo service zookeeper start
# verify it's started
# observe the logs - need to do this on every machine
cat /opt/kafka/logs/zookeeper.out | head -100
nc -vz localhost 2181
nc -vz localhost 2888
nc -vz localhost 3888
echo "ruok" | nc localhost 2181 ; echo
echo "stat" | nc localhost 2181 ; echo
bin/zookeeper-shell.sh localhost:2181
# not happy
ls /
