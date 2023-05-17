# Springboot + Actuator + Prometheus 매트릭 수집

- 개요

  본 장은 Springboot  의 JVM Memory 모니터링을 목적으로 Actuator , micrometer , simpleclient 와 같은 서브 프로젝트를 활용하여 매트릭을 수집하고 이를 Grafana에 시각화 하는 것 까지 진행한다.

- 환경 

  - Springboot 2.5.14
  - build tools : gradle 7.1.1



## 1. **spring boot actuator 란 무엇인가?**

> 공식 홈페이지 : https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html

> * 엑추에이터의 정의 : 액추에이터는 무언가를 움직이거나 제어하기 위한 기계 장치를 가리키는 제조 용어입니다. 액추에이터는 작은 변화로 많은 양의 동작을 생성할 수 있습니다.

Spring Boot에는 애플리케이션을 프로덕션으로 푸시할 때 애플리케이션을 모니터링하고 관리하는 데 도움이 되는 여러 가지 추가 기능이 포함되어 있습니다. Spring Boot actuator는 HTTP 엔드포인트 또는 JMX를 사용하여 애플리케이션을 관리하고 매트릭 수집을 통해 모니터링할 수 있습니다. 



## 2. 서브 라이브러리 설치

2.1. 라이브러리 추가 :  `build.gradle` 에 dependency를 추가한다.

~~~java
// Actuator + micreometer 로 prometheus 연동
implementation("org.springframework.boot:spring-boot-starter-actuator:2.5.14")
implementation("io.micrometer:micrometer-registry-prometheus:1.10.2")
implementation("io.prometheus:simpleclient:0.16.0")
~~~

- 추가하는 라이브러리의 버전은 개발 코드 상황에 따라 맞춰서 넣는다.

- spring-boot-starter-actuator : 매트릭을 수집해서 노출하는 actuator

- micrometer-registry-prometheus : prometheus 가  수집할 수 있도록 하는 actuator 확장 라이브러리

- simpleclient : prometheus가 수집할 수 있도록 하는 simple client

  

## 3. 매트릭 노출 설정 

> 참고: https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html

3.1.  actuator 매트릭의 엔드포인트 노출은 기본적으로 모두 `shutdown` 되어 있다. 이 중에 보고자 하는 매트릭을 설정 할 수 있다.  : `application.yml` 에 아래 내용 추가 

~~~yaml
management:
  endpoints:
    web:
      exposure:
        include: health, info, metrics, prometheus, loggers
  metrics:
    tags:
      application: metric-test
~~~

- management.endpoints.web.expose.include : `prometheus` 를 넣는 것이 중요. health, info 등은 선택사항이다.
- management.metrics.tags.applicaiton (Optional) : 태그를 추가할 수 있다.

3.2. `http://localhost:8080/actuator` 로 확인이 가능하다면 actuator로 exposure에 추가할 수 있는 매트릭을 확인 할 수 있다.



## 4. Prometheus 매트릭 수집

> 참고 : https://hudi.blog/spring-boot-actuator-prometheus-grafana-set-up/

4.1. prometheus는 기본적으로 polling 방식으로 Job을 이용하여 각 노출된 매트릭을 수집하는 아키텍처 구조를 갖고 있다. 따라서 JOB에 위의 과정을 통해 노출한 actuator 매트릭을 수집하는 설정을 한다. 
 이때 2가지 수집 방법이 있다.

1)  Java 백엔드 어플리케이션의 서비스에 직접 접근하는 방법

~~~
  - job_name: prometheus
    static_configs:
      - targets: ['<springboot-app-host>:<springboot-app-port>']
		metric_path: '/actuator/prometheus'
~~~

- `scrape_configs.static_configs.targets` : 메트릭을 수집할 호스트 정보를 명시한다. 만약 스프링부트 애플리케이션이 `localhost:8080` 에서 돌아가고 있다면, 그것을 적어주면 된다.

- `scrape_configs.static_configs.metric_path` : 메트릭 정보의 경로를 명시한다. Actuator를 사용하였으므로, 위와 같이 작성한다.

  > 자세한 설정 방법 : https://prometheus.io/docs/prometheus/latest/configuration/configuration/

2)  Prometheus 가 annotation tag를 기반으로 수집하도록 하는 방법

- prometheus  Job 설정

  - prometheus 는 prometheus.yml 파일에 추가.  보통 prometheus  configmap으로 설정해서 volume mount해서 사용한다.
  - 기본적으로 설치하면 default로 아래 내용이 존재함, 만약 없으면 추가한다.

  ~~~yaml
  - job_name: kubernetes-service-endpoints
          kubernetes_sd_configs:
            - role: endpoints
          relabel_configs:
            - action: keep
              regex: true
              source_labels:
                - __meta_kubernetes_service_annotation_prometheus_io_scrape
            - action: replace
              regex: (https?)
              source_labels:
                - __meta_kubernetes_service_annotation_prometheus_io_scheme
              target_label: __scheme__
            - action: replace
              regex: (.+)
              source_labels:
                - __meta_kubernetes_service_annotation_prometheus_io_path
              target_label: __metrics_path__
            - action: replace
              regex: ([^:]+)(?::\d+)?;(\d+)
              replacement: $1:$2
              source_labels:
                - __address__
                - __meta_kubernetes_service_annotation_prometheus_io_port
              target_label: __address__
            - action: labelmap
              regex: __meta_kubernetes_service_annotation_prometheus_io_param_(.+)
              replacement: __param_$1
            - action: labelmap
              regex: __meta_kubernetes_service_label_(.+)
            - action: replace
              source_labels:
                - __meta_kubernetes_namespace
              target_label: namespace
            - action: replace
              source_labels:
                - __meta_kubernetes_service_name
              target_label: service
            - action: replace
              source_labels:
                - __meta_kubernetes_pod_node_name
              target_label: node
  ~~~

  

- 수집할 service 의 annotation 설정

  ~~~yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: test-was
    labels:
      app: test-was
      service: test-was
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-name: "test-dev-was"
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb-ip"
      service.beta.kubernetes.io/aws-load-balancer-internal: "true"
      service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
      service.beta.kubernetes.io/aws-load-balancer-subnets: subnet-12345678a, subnet-12345678b
      ### 추가 부분 ###########################################
      prometheus.io/path: /actuator/prometheus
      prometheus.io/port: "30010"
      prometheus.io/scrape: "true"
      ########################################################
  spec:
    ports:
      - port: 8080
        targetPort: 8080
        protocol: TCP
    type: LoadBalancer
    selector:
      app: test-was
  ~~~

  

