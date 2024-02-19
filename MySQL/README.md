# Install MySQL in AmazonLinux2

1. amazon linux extra 패키지 설치 설정 허용
~~~bash
$ sudo amazon-linux-extras install epel -y 
~~~

2. MySQL repository 등록
~~~bash
$ sudo yum -y install https://dev.mysql.com/get/mysql80-community-release-el7-5.noarch.rpm
~~~

3. Install mysql server
~~~bash
$ sudo yum -y  install mysql-community-server 
~~~
* 만약 GPG 키 에러가 발생한다면?
  * /etc/yum.repos.d/mysql-community.repo 파일을 열어서 `gpgcheck=1` 부분을 `gpgcheck=0`으로 변경한다.

4. start mysql server
 * 서버가 시작할때 자동으로 mysql 서버가 시작할 수 있도록 설정하고, mysql 서버를 구동합니다.
~~~bash
$ systemctl enable mysqld 
$ systemctl start mysqld 
~~~
 * 참고
   * mysql 설정파일은 `/etc/my.cnf` 입니다. 
   * 샘플 
   ~~~bash
   [mysqld]
    datadir=/var/lib/mysql
    socket=/var/lib/mysql/mysql.sock

    log-error=/var/log/mysqld.log
    pid-file=/var/run/mysqld/mysqld.pid
    
    # Server
    server-id       = 1
    user            = mysql
    port            = 13306
    bind-address    = 0.0.0.0
    
    # character-set
    character-set-server    = utf8mb4
    collation-server        = utf8mb4_general_ci
    default-storage-engine  = InnoDB
    skip-name-resolve
    skip-external-locking
   ~~~

5. root 패스워드 찾기
* root 패스워드는 설치시 임시 생성됩니다. /var/log/mysql.log에서 확인할 수 있습니다.
~~~bash
$ cat /var/log/mysqld.log | grep "A temporary password"
~~~

6. MySQL 설치 후 보안 셋업
* MySQL 패키지로 제공하는 post-installation 스크립트는 기본적인 MySQL 기초 보안 설정에 도움이 됩니다.
  이 스크립트는 한번만 실행하여 설정하면 됩니다.
~~~bash
$ sudo mysql_secure_installation
~~~
* 보안규칙에 맞는 패스워드로 해야한다.
  예를들어 `qwer1234Q!` 이렇게 대소문자,숫자,특수문자가 다 들어가 있어야 한다. 

7. MySQL 접속
~~~bash
$ mysql -u root -p
~~~

8. root 패스워드 변경

