#!/bin/bash
# Packages
sudo apt-get update && \
      sudo apt-get -y install wget ca-certificates zip net-tools vim nano tar netcat

# Java Open JDK 8
sudo apt-get -y install default-jdk
java -version

# Disable RAM Swap - can set to 0 on certain Linux distro
sudo sysctl vm.swappiness=1
echo 'vm.swappiness=1' | sudo tee --append /etc/sysctl.conf

# Add hosts entries (mocking DNS) - put relevant IPs here
echo "
10.29.9.1 kafka1
10.29.9.1 zookeeper1
10.29.19.230 kafka2
10.29.19.230 zookeeper2
10.29.35.20 kafka3
10.29.35.20 zookeeper3" | sudo tee --append /etc/hosts

# download Zookeeper and Kafka. Recommended is latest Kafka (2.6) and Scala 2.12
wget http://apache.mirror.digitalpacific.com.au/kafka/2.6.0/kafka_2.13-2.6.0.tgz
tar -zvxf kafka_2.13-2.6.0.tgz
rm kafka_2.13-2.6.0.tgz
sudo mv kafka_2.13-2.6.0/ /opt/kafka
cd /opt/kafka/
# Zookeeper quickstart
cat config/zookeeper.properties
bin/zookeeper-server-start.sh config/zookeeper.properties
# binding to port 2181 -> you're good. Ctrl+C to exit

# Testing Zookeeper install
# Start Zookeeper in the background
bin/zookeeper-server-start.sh -daemon config/zookeeper.properties
bin/zookeeper-shell.sh localhost:2181
ls /
# demonstrate the use of a 4 letter word
echo "ruok" | nc localhost 2181 ; echo

# Install Zookeeper boot scripts
sudo vi /etc/systemd/system/zookeeper.service
# Insert the below text
      ```
      [Unit]
      Requires=network.target remote-fs.target
      After=network.target remote-fs.target

      [Service]
      Type=simple
      User=root
      ExecStart=/opt/kafka/bin/zookeeper-server-start.sh opt/kafka/config/zookeeper.properties
      ExecStop=/opt/kafka/bin/zookeeper-server-stop.sh
      Restart=on-abnormal

      [Install]
      WantedBy=multi-user.target
      ```

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
nc -vz localhost 2181
# by default, in latest versions, this is not whitelisted.  You will get an
# error, but that is ok, if it returns the shitelist msg that means it's up
echo "ruok" | nc localhost 2181 ; echo

# check the logs
cat logs/zookeeper.out
