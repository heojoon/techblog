# GitLab Quick Start

[ref] https://about.gitlab.com/install/#centos-7



## Requirement

* Cpu 2core / 4GB (minimum)



## Installation

1. Install git , sendmail

~~~bash
sudo yum -y install git
sudo yum -y install curl policycoreutils postfix 
sudo systemctl enable postfix 
sudo systemctl start postfix 
~~~



2. Install gitlab

~~~bash
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | sudo bash
sudo yum -y install gitlab-ce
~~~



3. 환경 설정

   sudo vi /etc/gitlab/gitlab.rb

- external_url 설정

  도메인 보유시 도메인 입력, AWS EC2 일 경우 EIP를 할당 받은 후 EIP를 입력

~~~bash
external_url 'http://서버아이피:8989'
~~~



* smtp설정,  gitlab에서 유저 인증이나 각종 알림의 용도로 사용됨

  ~~~bash
  gitlab_rails['smtp_enable'] = true
  gitlab_rails['smtp_address'] = "smtp.gmail.com"
  gitlab_rails['smtp_port'] = 587
  gitlab_rails['smtp_user_name'] = "heojoon0005@gmail.com"
  gitlab_rails['smtp_password'] = "zaq!xsw@cde#"
  gitlab_rails['smtp_domain'] = "smtp.gmail"
  gitlab_rails['smtp_authentication'] = "login"
  gitlab_rails['smtp_enable_starttls_auto'] = true
  gitlab_rails['smtp_tls'] = false
  gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
  ~~~

* 설정 업데이트 명령
  systemctl 재시작 명령으로 환경설정 업데이가 안되고 아래 명령으로만 변경한 설정 값이 적용 됨

  ~~~bash
  sudo gitlab-ctl reconfigure
  ~~~

* 웹브라우저 접속

  ~~~bash
  http://IP:8888
  ~~~

* root 계정 패스워드 초기 설정 후 로그인
  처음 접속하면 root 계정 패스워드를 입력하라고 나온다



## Create project repository

1. 소스 형상관리를 하고자 하는 프로젝트 생성이 필요
2. Group 생성 -> User 생성 -> Repository 생성 순으로 진행



