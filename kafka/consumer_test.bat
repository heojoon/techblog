docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic test-topic --from-beginning --consumer.config /etc/kafka/consumer_jaas.conf
