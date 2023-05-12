

# 로컬 개발용  Kafka 구성

## 1. 목적

- 로컬 개발시 단위 기능 테스트 등의 목적으로 브로커 1개 / 주키퍼 1개의 환경으로 가볍게 사용할 수 있도록 구성하였다.

- 실행 환경은 빠른 설치 구성으로 위해서 docker-compose로 구성하였다.

- 운영계 (SASL인증 존재)와 동일한 환경 제공을 위해서 SASL_PLAINTEXT 인증을 설정하였다. 



## 2. SASL이란? 

  >  **SASL**(Simple Authentication and Security Layer)은 [인터넷 프로토콜](https://ko.wikipedia.org/wiki/인터넷_프로토콜)에서 인증과 데이터보안을 위한 프레임워크이다. 이것은 애플리케이션 프로토콜들로부터 인증 메커니즘을 분리시킨다. 
  >
  >  데이터 교환 과정에서 PLAIN, SCRAM , GSAPI 등의 메커니즘을 사용하여 인증/인가를 할 수 있도록 해주며, 인증/인가에 이후 데이터 교환을 데이터 보안 계층 위에서 할 수 있도록 해주는 기술이다.
  >
  >  SASL이 지원하는 메커니즘은 수십가지에 달한다. 



## 3. Kafka의 SASL 지원 매커니즘

- Kafka의 경우 SASL이 지원하는 메커니즘은 SASL/GSAPI(kerveros) , SASL/PALIN , SASL/SCRAM , SASL/OATUHBEARER 이다. 

  - Kerberos는 노드간 통신에서 보안을 클라이언트가 티켓을 발급 받아 본인의 신원을 증명하면 인증을 하는 방식이다. 별도의 인증 및 티켓검증서버가 필요하며, 해당 서버가 불능이 될 경우 인증이 불가하다는 단점이 있다.

  - PLAIN 은 PLAINTEXT로 username/password를 설정하여 인증을 하는 가장 기본적인 방식이다. 평문을 주고 받으며, TLS 등을 사용하지 않을 경우 탈취 및 변조의 위험이 있다.

  - SCRAM은 PBKDF2 암호화 알고리즘을 활용해 생성된 해시를 활용하며, salt 와 count 를 부가적으로 전달하여 인증하는 방법이다.

  - OAUTHBEARER 은 OAuth2 스펙에 부합하는 토큰을 기반으로 인증하는 방법이다.

    

## 4. Kafka의 SASL 보안 설정 구성

- KAFKA는 JAAS를 활용해 SASL 구성을 통해 보안을 설정한다.  각 항목의 설정 방법은 우선순위로 작성

  - Broker (inter-broker) 

    - listener.name.{listenerName}.{saslMechanism}.sasl.jaas.config 프로퍼티 설정
    - JAAS Configuration 파일에서 {listenerName}.KafkaServer 섹션
    - JAAS Configuration 파일에서 KafkaServer 섹션

  - Brokder (zookeeper-connect)

    - Zookeeper 접속시 JAAS Configuration 파일에서 Server / Client 섹션

    - Zookeeper 의 service name (principal)의 기본값은 zookeeper이다. 이것을 변경하려면

      *-Dzookeeper.sasl.client.username=zk* 와 같은 식으로 VM args를 주고 실행해야 한다.

  - Client (Consumer / Producer)

    - sasl.jaas.config 프로퍼티를 설정
    - KafkaClient 섹션을 명시한 JAAS Configuration 파일을 작성

  - JAAS Configuration 파일을 작성했을 경우 애플리케이션 구동시 *-Djava.security.auth.login.config={JAAS File}* 을 VM Args 로 주고 실행해야 한다.



## 5. Kafka 설치 with SASL/PLAIN

- 구성파일 

  - `docker-compose.yaml `
    docker-compose 로 zookeeper 와 kafka를 구동할 매니페스트

  - `zookeeper_jaas.conf `
     zookeeper 에 접속시 사용할 계정 설정 , kafka 브로커에서 접속할 때 여기에 설정한 정보 값을 이용한다. 

  - `kafka_server_jaas.conf `

    consumer/producer 에서 kafka 브로커에 접속 할 때 사용하는 서버 계정 설정과 브로커-브로커 , 브로커-주키퍼 접속 살때 사용하는 클라이언트 계정 설정을 하는 파일

  - `consumer_jaas.conf `
    kafka console로 consumer 및 topic 생성시 사용할 설정 파일

  - `producer_jaas.conf`
    kafka console로 produce 할 때 사용할 설정 파일

- `docker-compose.yaml`

~~~yaml
version: '3'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.4.0
    container_name: zookeeper
    ports:
      - "2181:2181"
    environment:
      - ZOOKEEPER_CLIENT_PORT=2181
      - ZOOKEEPER_TICK_TIME=2000
      - ZOOKEEPER_AUTH_PROVIDER_1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider
      - ZOOKEEPER_REQUIRE_CLIENT_AUTH_SCHEME=sasl
      - ZOOKEEPER_JAAS_LOGIN_RENEW=3600000
      - ZOOKEEPER_SERVER_CNXN_FACTORY=org.apache.zookeeper.server.NettyServerCnxnFactory
      - ZOOKEEPER_ADMIN_ENABLE_SERVER=true
      - ZOOKEEPER_SASL_ENABLED=true
      - ZOOKEEPER_SASL_CLIENT=true
      - KAFKA_OPTS=-Djava.security.auth.login.config=/etc/zookeeper/zookeeper_jaas.conf

    volumes:
      - ./zookeeper_jaas.conf:/etc/zookeeper/zookeeper_jaas.conf

  kafka:
    image: confluentinc/cp-kafka:7.4.0
    container_name: kafka
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      # default config
      - KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181      
      # Auth config
      - KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=BROKER:SASL_PLAINTEXT
      - KAFKA_LISTENERS=BROKER://:9092
      - KAFKA_ADVERTISED_LISTENERS=BROKER://kafka:9092
      - KAFKA_LISTENER_NAME_BROKER_SASL_ENABLED_MECHANISMS=PLAIN
      - KAFKA_INTER_BROKER_LISTENER_NAME=BROKER
      - KAFKA_SASL_MECHANISM_INTER_BROKER_PROTOCOL=PLAIN
      # etc config
      - KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1
      - KAFKA_ALLOW_EVERYONE_IF_NO_ACL_FOUND=true
      - KAFKA_AUTO_CREATE_TOPICS_ENABLE=true
      - KAFKA_SUPER_USERS=User:admin
      - KAFKA_LOG4J_LOGGERS=DEBUG,stdout
      - KAFKA_OPTS=-Djava.security.auth.login.config=/etc/kafka/kafka_server_jaas.conf
    volumes:
      - ./kafka_server_jaas.conf:/etc/kafka/kafka_server_jaas.conf
      - ./consumer_jaas.conf:/etc/kafka/consumer_jaas.conf
      - ./producer_jaas.conf:/etc/kafka/producer_jaas.conf
~~~



- `zookeeper_jaas.conf`

~~~java
Server {
  org.apache.zookeeper.server.auth.DigestLoginModule required
  user_admin="admin1234"
  user_zookeeper="zookeeper";
};
~~~



- `kafka_server_jaas.conf`
  - KafkaServer 섹션
    -  org.apache.kafka.common.security.plain.PlainLoginModule required : SASL PLAIN 로그인 설정 선언
    - username : super 유저 이름
    - password : user 유저 패스워드
    - user_<유저이름>=<유저패스워드> 
      - ex) user_alice="alice-secret"
  - Client 섹션
    - org.apache.zookeeper.server.auth.DigestLoginModule required 브로커/주키퍼 로그인 설정 선언
    - username : 접속할 유저 이름
    - password : 접속할 유저의 패스워드

~~~java
KafkaServer {
  org.apache.kafka.common.security.plain.PlainLoginModule required
  username="admin"
  password="admin-secret"
  user_admin="admin-secret"
  user_alice="alice-secret"
  user_zookeeper="zookeeper";
};

Client {
    org.apache.zookeeper.server.auth.DigestLoginModule required
    username="zookeeper"
    password="zookeeper";
};
~~~



- `consumer_jaas.conf`
  - client.id : consume을 할 시스템(프로그램)의 ID
  - group.id: consume을 할 때 사용하는 그룹 ID
  - bootstrap.servers : 브로커 서버 정보
  - security.protocol : SECURITY 프로토콜 설정 
  - sasl.mechanism : SASL 매커니즘 선택
  - sasl.jaas.config : Consume 할때 SASL 을 사용할 시 설정 정보 

~~~java
client.id=test
group.id=test-group

bootstrap.servers=BROKER://localhost:9092
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN

sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \
    username="alice" \
    password="alice-secret";
~~~



- `producer_jaas.conf`
  - bootstrap.servers : 브로커 서버 정보
  - security.protocol : SECURITY 프로토콜 설정 
  - sasl.mechanism : SASL 매커니즘 선택
  - sasl.jaas.config : Produce 할때 SASL 을 사용할 시 설정 정보 

~~~java
bootstrap.servers=BROKER://localhost:9092
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN

sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \
  username="alice" \
  password="alice-secret";
~~~



- 위의 파일들을 동일한 디렉토리에 위치해 두고 docker 를 구동한다.
  - 프로세스가 올라온 것 까지 확인한다. 

~~~bash
# 구동
docker-compose up -d

# 프로세스 확인
docker-compose ps
NAME                IMAGE                             COMMAND                  SERVICE             CREATED             STATUS              PORTS
kafka               confluentinc/cp-kafka:7.4.0       "/etc/confluent/dock…"   kafka               13 minutes ago      Up 11 minutes       0.0.0.0:9092->9092/tcp
zookeeper           confluentinc/cp-zookeeper:7.4.0   "/etc/confluent/dock…"   zookeeper           13 minutes ago      Up 11 minutes       2888/tcp, 0.0.0.0:2181->2181/tcp, 3888/tcp

# 로그 확인 (필요시)
docker-compose logs kafka 
docker-compose logs zookeeper
~~~



## 6. Produce / Consume 테스트

- 토픽을 생성 
  - 토픽 생성시 인증이 필요하기 때문에 `--command-config` 옵션으로 미리 준비해 뒀던 jaas 정보를 함께 추가해준다.

~~~bash
docker-compose exec kafka kafka-topics --create --topic test-topic --partitions 1 --replication-factor 1 --bootstrap-server localhost:9092 --command-config /etc/kafka/consumer_jaas.conf
~~~



- 메세지를 발송 테스트 
  - 1부터 10까지 메세지를 test-topic에 발송한다.

~~~bash
docker-compose exec kafka bash -c "seq 10 | kafka-console-producer --request-required-acks 1 --broker-list localhost:9092 --topic test-topic --producer.config /etc/kafka/producer_jaas.conf && echo 'Produced 10 mesages.'"
~~~



- 메세지 수신 테스트
  - test-topic에서 메세지를 수신한다.

~~~bash
docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic test-topic --from-beginning --consumer.config /etc/kafka/consumer_jaas.conf
~~~



- 테스트 결과

~~~bash
# 발송
docker-compose exec kafka bash -c "seq 10 | kafka-console-producer --request-required-acks 1 --broker-list localhost:9092 --topic test-topic --producer.config /etc/kafka/producer_jaas.conf && echo 'Produced 10 mesages.'"
Produced 10 mesages.

# 수신
docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic test-topic --from-beginning --consumer.config /etc/kafka/consumer_jaas.conf
1
2
3
4
5
6
7
8
9
10
~~~



