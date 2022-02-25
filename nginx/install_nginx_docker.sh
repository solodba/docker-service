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
LABEL maintainer code-horse
RUN yum install -y gcc gcc-c++ make \
    openssl-devel pcre-devel gd-devel \
    iproute net-tools telnet wget curl && \
    yum clean all && \
    rm -rf /var/cache/yum/*

ADD nginx-1.15.5.tar.gz /
RUN cd nginx-1.15.5 && \
    ./configure --prefix=/usr/local/nginx \
    --with-http_ssl_module \
    --with-http_stub_status_module && \
    make -j 4 && make install && \
    mkdir /usr/local/nginx/conf/vhost && \
    cd / && rm -rf nginx* && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ENV PATH $PATH:/usr/local/nginx/sbin
COPY nginx.conf /usr/local/nginx/conf/nginx.conf
WORKDIR /usr/local/nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
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

# 创建Nginx镜像文件
create_nginx_image(){
  docker image build -t nginx:v1 -f $homedir/Dockerfile $homedir/
  result=$?
  repository=`docker image ls | grep 'nginx' | awk '{print $1}'`
  tag=`docker image ls | grep 'nginx' | awk '{print $2}'`
  if [ $result -eq 0 -a "$repository"="nginx" -a "$tag"="v1" ];then
    echo -e "#########################################################"
    echo -e "###################Nginx镜像文件创建成功!################"
    echo -e "#########################################################\n"
  else
    echo -e "#########################################################"
    echo -e "###################Nginx镜像文件创建失败!################"
    echo -e "#########################################################\n"
  fi

}

# 通过Nginx镜像文件创建容器
create_nginx_docker(){
 docker run -d -p 88:80 --name web-nginx -m="256M" -h nginx nginx:v1
 result=$?
 cnt=`docker container ls -a | grep web-nginx | wc -l`
 if [ $result -eq 0 -a $cnt -eq 1 ];then
    echo -e "#########################################################"
    echo -e "#####################Nginx容器创建成功!##################"
    echo -e "#########################################################\n"
 else
    echo -e "#########################################################"
    echo -e "#####################Nginx容器创建失败!##################"
    echo -e "#########################################################\n"
 fi	 
}

# 创建Nginx容器
install_nginx_docker(){
   check_docker
   check_pkg
   create_dockerfile
   create_nginx_image
   create_nginx_docker       
}

echo -e "#########################################################"
echo -e "###################Nginx容器开始生成#####################"
echo -e "#########################################################\n"
install_nginx_docker
echo -e "#########################################################"
echo -e "###################Nginx容器结束生成#####################"
echo -e "#########################################################\n"
