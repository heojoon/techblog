# ECR Quick Start



## Docker Image upload

* Dockerfile 생성

~~~
FROM ubuntu:18.04

# Install dependencies
RUN apt-get update && \
 apt-get -y install apache2

# Install apache and write hello world message
RUN echo 'Hello World!' > /var/www/html/index.html

# Configure apache
RUN echo '. /etc/apache2/envvars' > /root/run_apache.sh && \
 echo 'mkdir -p /var/run/apache2' >> /root/run_apache.sh && \
 echo 'mkdir -p /var/lock/apache2' >> /root/run_apache.sh && \ 
 echo '/usr/sbin/apache2 -D FOREGROUND' >> /root/run_apache.sh && \ 
 chmod 755 /root/run_apache.sh

EXPOSE 80

CMD /root/run_apache.sh
~~~



* 도커 빌드

~~~bash
docker build -t hello-world .
~~~



* 도커 빌드 된 이미지 확인

~~~bash
docker images --filter reference=hello-world
~~~



* ECR 생성 (aws cli 설치 및 설정이 완료 선행 필요)

~~~bash
aws ecr create-repository --repository-name hello-repository --region ap-northeast-2
~~~

- ECR 생성 결과

~~~json
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:ap-northeast-2:632162424742:repository/hello-repository",
        "registryId": "632162424742",
        "repositoryName": "hello-repository",
        "repositoryUri": "632162424742.dkr.ecr.ap-northeast-2.amazonaws.com/hello-repository",
        "createdAt": 1646307095.0,
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": false
        }
    }
}
~~~



*  `repositoryUri` 값으로 태그 지정합니다.

  ~~~bash
  docker tag hello-world 632162424742.dkr.ecr.ap-northeast-2.amazonaws.com/hello-repository
  ~~~

* ECR 로그인 수행 수행

  ~~~bash
  aws ecr get-login-password | docker login --username AWS --password-stdin 632162424742.dkr.ecr.ap-northeast-2.amazonaws.com
  ~~~

* ECR 로 이미지 푸시

  ~~~bash
  docker push 632162424742.dkr.ecr.ap-northeast-2.amazonaws.com/hello-repository
  ~~~

* ECR 삭제 (정리시)

  ~~~bash
  aws ecr delete-repository --repository-name hello-repository --region ap-northeast-2 --force
  ~~~





# ECS 구축 step by step

> \[참고\] https://yunsangjun.github.io/cloud/2019/06/23/aws-ecs-01.html

# IAM 생성

* User : devheo
* Policy : AWSCodeCommitFullAccess
* AccessKey

~~~
AKIAZGL6RC6TNHMPWRV5
sWEbKIzkLJv4jwin8dRuORsSr/zflHS9MnnknKON
~~~

* HTTPS Git 자격증명

~~~
devheo-at-632162424742
C5FIYSWF/PoVjlUfq1q9thWfuzhr3NPH/W92M2hHESo=
~~~



# code commit 저장소 구성

* code-commit 저장소 생성 후 로컬에 clone

~~~bash
git clone https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/cicd-demo
~~~

* 샘플 코드 다운로드

~~~bash
$ wget https://github.com/spring-projects/spring-petclinic/archive/refs/heads/main.zip
unzip main.zip
mv spring-petclinic-main/* .
rm -rf spring-petclinic-main
~~~

* 저장소에 Push

~~~
git config --global user.email "heojoon48@gmail.com"
git config --global user.name "heojoon"
git add --all
git commit -m "Init"
git push
~~~



# ECR , CodeBuild 구성

* Private로 생성

~~~
632162424742.dkr.ecr.ap-northeast-2.amazonaws.com/cicd-demo
~~~

* IAM 정책 생성

  * CodeBuild에서 ECR 접근할 수 있는 고객관리형 정책 생성

    ~~~yaml
      {
          "Statement": [
              {
                  "Action": [
                      "ecr:BatchCheckLayerAvailability",
                      "ecr:CompleteLayerUpload",
                      "ecr:GetAuthorizationToken",
                      "ecr:InitiateLayerUpload",
                      "ecr:PutImage",
                      "ecr:UploadLayerPart"
                  ],
                  "Resource": "*",
                  "Effect": "Allow"
              }
          ],
          "Version": "2012-10-17"
      }
    ~~~

  * 정책 이름 : CodeBuildECRPolicy-cicd-demo

## BuildSpec 생성

* [Document] https://docs.aws.amazon.com/ko_kr/codebuild/latest/userguide/build-spec-ref.html

* BuildSpec 파일 생성

  * 로컬에 git clone 받아 놓은 위치로 가서 아래 buildspec.yml 파일 생성

    ~~~yml
    version: 0.2
    
    env:
      variables:
        AWS_DEFAULT_REGION: "ap-northeast-2"
        AWS_ACCOUNT_ID: "632162424742"
        IMAGE_REPO_NAME: "cicd-demo"
        IMAGE_TAG: "latest"
    
    phases:
      install:
        runtime-versions:
          java: corretto11
      pre_build:
        commands:
          - echo ====== Envionment ======
          - echo IMAGE_REPO_NAME is $IMAGE_REPO_NAME
          - echo IMAGE_TAG is $IMAGE_TAG
      build:
        commands:
          - echo Build started on `date`
          - echo Building the Docker image...
          #- mvn clean package
          - mvn package
      post_build:
        commands:
          - echo Build completed on `date`
          - echo Logging in to Amazon ECR...
          #- aws ecr get-login --no-include-email --region $AWS_DEFAULT_REGION
          - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
          - echo Building the Docker image... `date`
          - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
          - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
          - echo Pushing the Docker image... `date`
          - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
    cache:
      paths:
        - '/root/.m2/**/*'
    ~~~

* Docker 파일 생성

  * `Dockerfile`을 CodeCommit에 생성한 `cicd-demo` 저장소 root에 생성

    ~~~bash
    FROM openjdk:8-jdk-alpine
    ADD target/spring-petclinic-2.1.0.BUILD-SNAPSHOT.jar app.jar
    ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
    ~~~

* repository에 Push

  ~~~bash
  git add --all
  git commit -m "create buildspec and dockerfile"
  git push
  ~~~

  

# Codebuild 프로젝트 구성

* codebuild > 메인화면 > 빌드프로젝트 생성

* 프로젝트 설정

  * 프로젝트 이름 : `cicd-demo`

  * 빌드 배지 활성화 체크

  * 소스

    * 소스 공급자 `AWS CodeCommit` 선택
    * 리포지토리 `cicd-demo` 선택

  * 이미지

    - 환경 이미지 > `관리형 이미지` 선택
    - 운영 체제 > `Ubuntu 선택` 선택
    - 런타임 > `Standard` 선택
    - 이미지 > `aws/codebuild/standart:4.0` 선택
    - 이미지 버전 > `이 런타임 버전에 항상 최신 이미지 사용` 선택
    - 권한이 있음 체크

  * 역할

    * 서비스 역할 > `새 서비스 역할` 선택
    * 역할 이름 `codebuild-cicd-demo-service-role` 입력

  * 추가구성

    * 환경변수

      | 이름               | 값             |
      | ------------------ | -------------- |
      | AWS_DEFAULT_REGION | ap-northeast-2 |
      | AWS_ACCOUNT_ID     | 632162424742   |
      | IMAGE_REPO_NAME    | cicd-demo      |
      | IMAGE_TAG          | latest         |
  
  * BuildSpec 
    
    * 빌드 사양 > `buildspec 파일 사용` 선택



## CodeBuild 역할과 정책 연결

* CodeBuild용 IAM 역할이 생성됨, 역할에 사전 준비에서 생성한 정책을 연결
* IAM  > AWS Account > 역할
* 메인 화면 > 검색 창 > `codebuild` 입력 > `codebuild-cicd-demo-service-role` 
* 권한 탭 > `정책 연결` 버튼 선택
* 정책 필터 > `codebuild` 입력 > `CodeBuildECRPolicy-cicd-demo-ap-northeast-2` 선택 > `정책 연결` 버튼 선택

> 권한 정책이 2개가 됨 
>
> - CodeBuildBasePolicy-cicd-demo-ap-northeast-2 
>
> - CodeBuildECRPolicy-cicd-demo



## CodeBuild 시작

> \[참고\] [docker push sampe](https://docs.aws.amazon.com/ko_kr/codebuild/latest/userguide/sample-docker.html)

* CodeBuild > 빌드프로젝트 > cicd-demo > `빌드 시작`  > `지금 빌드`



## CodeBuild 캐시 설정 

* CodeBuild 서비스에서는 소스코드를 빌드하기 위한 파일을 한번만 다운받고 이 후에는 다시 받지 않도록 캐시 옵션을 설정할 수 있습니다.
* CodeBuild Console에 접속 > 빌드 > 프로젝트 빌드 > `cicd-demo` 선택 > `빌드 세부 정보` 탭 선택
* 아티팩트 > `편집` 버튼 선택
* 추가 구성 메뉴 확장 > 캐시 유형 `Amazon S3` 선택 > 캐시 버킷 선택 (S3 콘솔에서 사전 생성 필요)

![image-20220306120720190](C:\Users\허준\git\devopsOnAWS\ecs\image-20220306120720190.png)





# ECS Cluster 생성

> https://yunsangjun.github.io/cloud/2019/06/23/aws-ecs-01.html

- ECS Console에 접속 > 왼쪽 메뉴 > Amazon ECS > 클러스터 선택
- 메인 화면 > `클러스터 생성` 버튼 선택
- 클러스터 템플릿 선택 > `네트워킹 전용(AWS Fargate 제공)` 선택
- 클러스터 구성 > 클러스터 이름 `cicd-demo` 입력 > `생성` 버튼 선택



# ECS Task 생성

## IAM 역할 생성

- IAM Console에 접속 > 왼쪽 메뉴 > AWS Account > 역할 선택
- 메인 화면 > `역할 만들기` 버튼 선택
- 개체 선택에서 `AWS 서비스` 선택 > 사용 사례 > 다른 AWS 서비스의 사용 사례 :   `Elastic Container Service` 선택 > `Elastic Container Service Task` 선택
- 권한 정책 연결 > 정책 필터에 `ecs` 입력 > `AmazonECSTaskExecutionRolePolicy` 선택 > `다음: 태그` 버튼 선택
- 역할 이름을 `ecstask-cicd-demo-role` 입력 > 역할 검토 > `역할 만들기` 버튼 선택 

## ECS 작업 정의

* ECS Console에 접속 > 왼쪽 메뉴 > Amazon ECS > `작업 정의` 선택
* 메인 화면 > `새 작업 정의 선택` 버튼 선택
* Fargate 선택 > `다음 단계` 버튼 선택
* 작업 및 컨테이너 정의 구성
  * 태스크 정의 이름 : `cicd-demo` 
  * 태스크 역할 :  `ecstask-cicd-demo-role`  선택 (위 IAM 역할 생성 단계에서 사전에 생성함)
  * 운영 체제 패밀리 : `Linux`
* 작업 실행 IAM 역할
  * 작업 실행 역할 `ecstask-cicd-demo-role`
* 작업 크기
  * 작업 메모리 : `1GB`
  * 작업 CPU(vCPU) : `0.5 vCPU`

* 컨테이너 정의 
  * `컨테이너 추가` 버튼 선택
  * 팝업 창 > 컨테이너 이름 > `cicd-demo` 입력
  * 이미지 > `이미지 주소` 입력(cicd-demo ECR 주소) : `632162424742.dkr.ecr.ap-northeast-2.amazonaws.com/cicd-demo`
  * 메모리 제한 > `소프트 제한` 선택 > `500` 입력
  * 포트 매핑 > `8080` 입력 > `추가` 버튼 선택
  * `추가`  버튼을 누름 (팝업 창이 닫힘)
  * `생성`  (작업 정의 생성 완료)

# ECS Service 구성

AWS에서 ECS(Elastic Container Service)의 서비스(ECS Service)를 통해 작업 정의(컨테이너)를 관리할 수 있습니다.  로드 밸런서와 연동하여 트랙픽을 다중 컨테이너에 분산할 수 있습니다.  Auto Scailing을 사용하여 사용량에 기반하여 컨테이너 개수를 조절할 수 있습니다.



## 보안그룹 생성

* 보안 그룹 할당 > 새 보안 그룹 생성 선택
* 보안 그룹 이름에 `cicd-demo-sg` 입력
* 설명에 `Allow http` 입력
* 인바운드 규칙 `HTTP` 선택 > `다음` 버튼 선택
* 소스 : `0.0.0.0/0`



## 로드밸런싱 > 대상그룹 생성 

* Target type : `IP addresses`
* Target group name : `cicd-demo-service`
* Protocol : `HTTP` : Port : `80`
* Health checks (상태 검사)
  * Advanced health check settings 
    * Override : 8080

* Register targets
  * 설정 변경 없이 `다음` 버튼 선택

* 결과화면 EC2 > Target groups

![image-20220307095033718](D:\git\devopsOnAWS\ecs\image-20220307095033718.png)





## 로드밸런싱 > 로드밸런서 생성

* EC2 Console에 접속 > 왼쪽 메뉴 > 로드 밸런싱 > 로드밸런서 선택

* 메인 화면 > `로드 밸런서 생성` 버튼 선택

* 로드밸런서 유형 선택 > Application Load Balancer > `생성` 버튼 선택

* Basic configuration

  * Load balancer name : `cicd-demo`
  * Scheme : `Internet-facing`

* 리스너 & 라우팅

  * 기본 값인 `HTTP, 80` 그대로 사용 (애플리케이션 접속시 http를 사용하여 접속)
  * Default action : Forward to `cicd-demo-service` 선택 (위 단계에서 생성)

* 가용 영역 > VPC, 가용 영역 및 Subnet(Public) 선택 > `다음` 버튼 선택

  * Mappings : `ap-northeast-2a` ,  `ap-northeast-2b`

* 보안 그룹  : `cide-demo-sg` 선택 (위 단계에서 생성)

* `Create Loadbalancer` 버튼 클릭, 완료 

  > 프로비저닝에 시간이 일부 소요됨



## 서비스 생성

* ECS Console에 접속 > 왼쪽 메뉴 > Amazon ECS > 클러스터 선택

* 클러스터 리스트 > `cicd-demo` 선택

* 서비스 탭 > `생성` 버튼 선택

* 서비스 구성

  * 시작 유형 > `FARGATE` 선택
  * 서비스 이름 > `cicd-demo` 입력
  * 작업 개수 > `2` 입력

* 배포 > `롤링 업데이트` 선택 > `다음` 버튼 선택

* 네트워크 구성 > VPC 및 보안 그룹

  * 클러스터 VPC > 컨테이너가 위치할 VPC를 선택 

  * 서브넷 > 컨테이너가 위치할 서브넷을 선택 (이 문서에서는 Private 서브넷을 기준으로 작성함)

    * AZ-a , AZ-b

  * 보안 그룹 

    * 편집 선택 > 보안 그룹 구성 : `cicd-demo-service` 생성
    * 인바운드 규칙 > 유형에서 Custom TCP 선택 > 포트 범위 8080 입력(로드밸런서에서 컨테이너의 8080 포트로의 인바운드 트래픽)

    ![image-20220307113941460](D:\git\devopsOnAWS\ecs\image-20220307113941460.png)

  * 자동 할당 퍼블릭 IP > `ENABLE` 

>- 자동 할당 퍼블릭 IP를 DISABLED로 선택할 경우 컨테이너에 퍼블릭 IP가 할당되지 않습니다.  컨테이너에서 외부와의 통신을 하려면 컨테이너가 위치한 Private 서브넷이 외부와 통신할 수 있는 `NAT와 연결 필요`되어야 합니다.
>- 자동 할당 퍼블릭 IP를 ENABLED로 선택할 경우 컨테이너에 퍼블릭 IP가 할당됩니다.  컨테이너는 `Public 서브넷에 위치`하고 해당 서브넷은 IGW(Internet Gateway)와 연결되어 있어야 합니다.  

:arrow_right: 자동 할당 퍼블릭 IP를 `DISABLE`로 할 경우 , NAT G/W를 만들어야 한다. 이 과정에서는 Skip

:arrow_right: 자동 할당 퍼블릭 IP를 `ENABLE`로 해서 진행합니다. 





* 로드밸런싱
  * 로드 밸런서 유형 > Application Load Balancer 선택
  * 서비스의 IAM 역할 선택 > 로드 밸런서 이름 :  `cicd-demo` 선택(사전 준비에서 생성)



* 로드 밸런싱할 컨테이너
  * 컨테이너 이름:포트  `cicd-demo:8080:8080`   (작업정의에서 생성) > `ELB 추가` 버튼 선택
  * 리스너 포트 > `80:HTTP` 선택 (사전 준비에서 생성)
  * 대상 그룹 이름 > `cicd-demo-service` 선택



* 서비스 검색 (선택 사항)
  * 서비스 검색 통합 활성화 [v]
  * 네임스페이스 이름 : `cicd-demo-local`
  * 서비스 검색 이름 : `cicd-demo`
  * ECS 작업상태 전파 활성화 [v]
  * 서비스 검색을 위한 DNS 레코드 
    * DNS 레코드 유형 : A
    * TTL : 60초

![image-20220307115252880](D:\git\devopsOnAWS\ecs\image-20220307115252880.png)



* Auto Scaling (선택사항) > 원하는 서비스 개수를 조정하지 마십시오
* 서비스 검토 > 완료



## 서비스 확인

이제 서비스가 정상적으로 구성되었는지 확인해보겠습니다.

* ECS Console에 접속 > 왼쪽 메뉴 > Amazon ECS > 클러스터 선택
* 클러스터 리스트 > `cicd-demo` 선택
* 서비스 탭 선택 > 상태가 <font color=lightgreen>**ACTIVE**</font>인지 확인
* 작업 탭 선택 > 마지막 상태/원하는 상태 가  <font color=lightgreen>**RUNNING**</font> 인지 확인
* EC2 Console에 접속 > 왼쪽 메뉴 > 로드 밸런싱 > 로드밸런서 선택
* 로드밸런싱 > 대상그룹 > `cicd-demo-service` > Targets > `Healty` 확인
* 로드밸런싱 > 로드밸런서 >  `cicd-demo`  의 상태가 `활성` 확인
  * DNS 이름 복사 > 웹브라우저에 붙여넣기 후 접속
  * 아래와 같은 화면 나오면 성공

![image-20220307142247647](D:\git\devopsOnAWS\ecs\image-20220307142247647.png)

# ECR 인터페이스 VPC 엔드포인트 (Private Link) 구성

인터페이스 VPC 엔드포인트를 사용하도록 Amazon ECR을 구성하여 VPC의 보안 상태를 향상시킬 수 있습니다. VPC 엔드포인트는 프라이빗 IP 주소를 통해 Amazon ECR APIs에 비공개로 액세스할 수 있는 기술인 AWS PrivateLink로 구동됩니다. AWS PrivateLink는 VPC 및 Amazon ECR 간의 모든 네트워크 트래픽을 Amazon 네트워크로 제한합니다. 인터넷 게이트웨이, NAT 디바이스 또는 가상 프라이빗 게이트웨이가 필요 없습니다.



* Amazon EC2 인스턴스에서 호스팅되는 Amazon ECS 작업이 Amazon ECR에서 프라이빗 이미지를 가져올 수 있도록 하려면 Amazon ECS용 인터페이스 VPC 엔드포인트도 생성해야 합니다. 

> 중요 
>
> Fargate 에서 호스팅되는 Amazon ECS 작업에는 Amazon ECS 인터페이스 VPC 엔드포인트가 필요하지 않습니다.

- 플랫폼 버전 `1.3.0` 이하를 사용하여 Fargate에서 호스팅되는 Amazon ECS 작업은 **com.amazonaws.`region`.ecr.dkr** Amazon ECR VPC 엔드포인트 및 Amazon S3 게이트웨이 엔드포인트만을 사용하여 이 기능을 활용할 수 있습니다.
- 플랫폼 버전 `1.4.0` 이상을 사용하여 Fargate에서 호스팅되는 Amazon ECS 태스크를 수행하려는 경우, **com.amazonaws.`region`.ecr.dkr** 및 **com.amazonaws.`region`.ecr.api** Amazon ECR VPC 엔드포인트뿐만 아니라 Amazon S3 게이트웨이 엔드포인트까지 사용해야 이 기능을 활용할 수 있습니다



## AWS 인터페이스 VPC 엔드포인트 생성

> [AWS VPC 엔드포인트 생성 공식문서](https://docs.aws.amazon.com/ko_kr/vpc/latest/privatelink/vpce-interface.html#create-interface-endpoint)



* VPC > 엔드포인트 > 엔드포인트 생성
* 이름 태그 : `ecr-cicd-demo-endpoint`

