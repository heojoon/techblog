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
sudo yum -y  install mysql-community-server 
~~~

4. start mysql server
~~~bash
systemctl active mysqld 
systemctl start mysqld 
~~~