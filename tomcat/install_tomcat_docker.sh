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
ENV VERSION=8.5.43
RUN yum install java-1.8.0-openjdk wget curl unzip iproute net-tools -y && \
    yum clean all && \
    rm -rf /var/cache/yum/*
ADD apache-tomcat-${VERSION}.tar.gz /usr/local/
RUN mv /usr/local/apache-tomcat-${VERSION} /usr/local/tomcat && \
    sed -i '1a JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom"' /usr/local/tomcat/bin/catalina.sh && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ENV PATH $PATH:/usr/local/tomcat/bin
WORKDIR /usr/local/tomcat
EXPOSE 8080
CMD ["catalina.sh", "run"]
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

# 创建tomcat镜像文件
create_tomcat_image(){
  docker image build -t tomcat:v1 -f $homedir/Dockerfile $homedir/
  result=$?
  repository=`docker image ls | grep 'tomcat' | awk '{print $1}'`
  tag=`docker image ls | grep 'tomcat' | awk '{print $2}'`
  if [ $result -eq 0 -a "$repository"="tomcat" -a "$tag"="v1" ];then
    echo -e "#########################################################"
    echo -e "###################tomcat镜像文件创建成功!###############"
    echo -e "#########################################################\n"
  else
    echo -e "#########################################################"
    echo -e "###################tomcat镜像文件创建失败!###############"
    echo -e "#########################################################\n"
  fi

}

# 通过tomcat镜像文件创建容器
create_tomcat_docker(){
 docker run -d -p 89:8080 --name web-tomcat -m="256M" -h tomcat tomcat:v1
 result=$?
 cnt=`docker container ls -a | grep web-tomcat | wc -l`
 if [ $result -eq 0 -a $cnt -eq 1 ];then
    echo -e "#########################################################"
    echo -e "#####################tomcat容器创建成功!##################"
    echo -e "#########################################################\n"
 else
    echo -e "#########################################################"
    echo -e "#####################tomcat容器创建失败!##################"
    echo -e "#########################################################\n"
 fi	 
}

# 创建tomcat容器
install_tomcat_docker(){
   check_docker
   check_pkg
   create_dockerfile
   create_tomcat_image
   create_tomcat_docker       
}

echo -e "#########################################################"
echo -e "###################tomcat容器开始生成####################"
echo -e "#########################################################\n"
install_tomcat_docker
echo -e "#########################################################"
echo -e "###################tomcat容器结束生成####################"
echo -e "#########################################################\n"
