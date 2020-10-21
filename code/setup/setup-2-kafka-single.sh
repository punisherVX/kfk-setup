#!/bin/bash

# Add file limits configs - allow to open 100,000 file descriptors
echo "* hard nofile 100000
* soft nofile 100000" | sudo tee --append /etc/security/limits.conf

# reboot for the file limit to be taken into account
sudo reboot
sudo servicetbd-zookeeper start  # this should already be started?
sudo mkdir -p /data/kafka
sudo chown -R pensando:pensando /data/kafka

# edit kafka configuration
rm /opt/kafka/config/server.properties
#cp ../kafka/server.properties /opt/config/server.properties
vi /opt/kafka/config/server.properties  # Change the broker ID and advertised.listener!!!!

# launch kafka
/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
# sudo vi /opt/kafka/config/server.properties
# (ctrl-C after you verify it's running with no errors)

# Install Kafka boot scripts
cp ../kafka/kafka_startup_systemV /etc/systemd/system/kafka.service
# sudo vi /etc/systemd/system/kafka.service

# enable the service and start it
sudo systemctl enable kafka.service
sudo systemctl start kafka.service
sudo systemctl status kafka.service

# verify it's working
nc -vz tbd-kafka1 9092
nc -vz tbd-kafka2 9092
nc -vz tbd-kafka3 9092
# look at the server logs
cat /opt/kafka/logs/server.log

# Test that we can create a topic and read from it
/opt/kafka/bin/kafka-topics.sh --zookeeper tbd-zookeeper1:2181,tbd-zookeeper2:2181,tbd-zookeeper3:2181/kafka --create --topic first_topic --replication-factor 3 --partitions 3

# we can publish data to Kafka using the bootstrap server list!
/opt/kafka/bin/kafka-console-producer.sh --broker-list tbd-kafka1:9092,tbd-kafka2:9092,tbd-kafka3:9092 --topic second_topic

/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server tbd-kafka1:9092,tbd-kafka2:9092,tbd-kafka3:9092 --topic second_topic --from-beginning

# make sure to fix the __consumer_offsets topic
/opt/kafka/bin/kafka-topics.sh --zookeeper tbd-zookeeper1:2181/kafka --config min.insync.replicas=1 --topic __consumer_offsets --alter

# we can create topics with replication-factor 3 now!
/opt/kafka/bin/kafka-topics.sh --zookeeper tbd-zookeeper1:2181,tbd-zookeeper2:2181,tbd-zookeeper3:2181/kafka --create --topic third_topic --replication-factor 3 --partitions 3

# let's list topics
/opt/kafka/bin/kafka-topics.sh --zookeeper tbd-zookeeper1:2181,tbd-zookeeper2:2181,tbd-zookeeper3:2181/kafka --list

# publish some data
/opt/kafka/bin/kafka-console-producer.sh --broker-list tbd-kafka1:9092,tbd-kafka2:9092,tbd-kafka3:9092 --topic third_topic

# check the data from another server
 /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server tbd-kafka1:9092,tbd-kafka2:9092,tbd-kafka3:9092 --topic third_topic --from-beginning

# let's delete that topic
/opt/kafka/bin/kafka-topics.sh --zookeeper tbd-zookeeper1:2181,tbd-zookeeper2:2181,tbd-zookeeper3:2181/kafka --delete --topic third_topic

# it should be deleted shortly:
/opt/kafka/bin/kafka-topics.sh --zookeeper tbd-zookeeper1:2181,tbd-zookeeper2:2181,tbd-zookeeper3:2181/kafka --list


# After, you should see three brokers here
/opt/kafka/bin/zookeeper-shell.sh localhost:2181
ls /kafka/brokers/ids
