#!/bash/bin

# 定义家目录
homedir=$PWD

# 检查Docker服务是否开启
check_docker(){
status=`systemctl status docker | grep -i 'Active' | awk -F ':' '{print $2}' | awk '{print $1}'`
if [ "$status" = "active" ];then
    echo -e "#########################################################"
    echo -e "#####################Docker服务已经开启！################"
    echo -e "#########################################################\n"
else
    echo -e "#########################################################"
    echo -e "###########Docker服务已经停止！退出安装！################"
    echo -e "#########################################################\n"	
    exit 0
fi
}

# 检查所需包和清单文件是否存在
check_pkg(){
  if [ ! -f $homedir/swl.conf ];then
      echo -e "#########################################################"
      echo -e "####安装所需清单文件swl.conf不存在！退出安装！####"
      echo -e "#########################################################\n"
      exit 0
  else
      echo -e "#########################################################"
      echo -e "###############安装所需清单文件swl.conf存在!#############"
      echo -e "#########################################################\n"
  fi
  
 while read line
  do
    name=`echo $line | awk '{print $1'}`
    if [ ! -f $homedir/$name ];then
      echo -e "#########################################################"
      echo -e "###$homedir/$name文件不存在!退出安装!###"
      echo -e "#########################################################\n"
      exit 0
    else
      echo -e "#########################################################"
      echo -e "###$homedir/$name文件存在!###"
      echo -e "#########################################################\n"
    fi
  done < $homedir/swl.conf
}

# 创建Dockerfile文件
create_dockerfile(){
cat > $homedir/Dockerfile << "EOF"
FROM centos:7
LABEL MAINTAINER code-horse
RUN yum install epel-release -y && \
    yum install -y gcc gcc-c++ make gd-devel libxml2-devel \
    libcurl-devel libjpeg-devel libpng-devel openssl-devel \
    libmcrypt-devel libxslt-devel libtidy-devel autoconf \
    iproute net-tools telnet wget curl && \
    yum clean all && \
    rm -rf /var/cache/yum/*

ADD php-5.6.36.tar.gz /
RUN cd php-5.6.36 && \
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --enable-fpm --enable-opcache \
    --with-mysql --with-mysqli --with-pdo-mysql \
    --with-openssl --with-zlib --with-curl --with-gd \
    --with-jpeg-dir --with-png-dir --with-freetype-dir \
    --enable-mbstring --with-mcrypt --enable-hash && \
    make -j 4 && make install && \
    cp php.ini-production /usr/local/php/etc/php.ini && \
    cp sapi/fpm/php-fpm.conf /usr/local/php/etc/php-fpm.conf && \
    sed -i "90a \daemonize = no" /usr/local/php/etc/php-fpm.conf && \
    mkdir /usr/local/php/log && \
    cd / && rm -rf php* && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ENV PATH $PATH:/usr/local/php/sbin
COPY php.ini /usr/local/php/etc/
COPY php-fpm.conf /usr/local/php/etc/
WORKDIR /usr/local/php
EXPOSE 9000
CMD ["php-fpm"]
EOF

# 判断文件是否创建成功
if [ -f $homedir/Dockerfile ];then
	echo -e "#########################################################"
	echo -e "###################Dockerfile文件创建成功！##############"
	echo -e "#########################################################\n"
else
	echo -e "#########################################################"
        echo -e "###################Dockerfile文件创建失败！##############"
        echo -e "#########################################################\n"
fi

}

# 创建php镜像文件
create_php_image(){
  docker image build -t php:v1 -f $homedir/Dockerfile $homedir/
  result=$?
  repository=`docker image ls | grep 'php' | awk '{print $1}'`
  tag=`docker image ls | grep 'php' | awk '{print $2}'`
  if [ $result -eq 0 -a "$repository"="php" -a "$tag"="v1" ];then
    echo -e "#########################################################"
    echo -e "###################php镜像文件创建成功!################"
    echo -e "#########################################################\n"
  else
    echo -e "#########################################################"
    echo -e "###################php镜像文件创建失败!################"
    echo -e "#########################################################\n"
  fi

}

# 通过php镜像文件创建容器
create_php_docker(){
 docker run -d --name web-php -m="256M" -h php php:v1
 result=$?
 cnt=`docker container ls -a | grep web-php | wc -l`
 if [ $result -eq 0 -a $cnt -eq 1 ];then
    echo -e "#########################################################"
    echo -e "#####################php容器创建成功!##################"
    echo -e "#########################################################\n"
 else
    echo -e "#########################################################"
    echo -e "#####################php容器创建失败!##################"
    echo -e "#########################################################\n"
 fi	 
}

# 创建php容器
install_php_docker(){
   check_docker
   check_pkg
   create_dockerfile
   create_php_image
   create_php_docker       
}

echo -e "#########################################################"
echo -e "###################php容器开始生成#####################"
echo -e "#########################################################\n"
install_php_docker
echo -e "#########################################################"
echo -e "###################php容器结束生成#####################"
echo -e "#########################################################\n"

