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
FROM java:8-jdk-alpine
LABEL maintainer code-horse
ENV JAVA_OPTS="$JAVA_OPTS -Dfile.encoding=UTF8 -Duser.timezone=GMT+08"
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
    apk add -U tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
COPY hello.jar /
EXPOSE 8888
CMD ["/bin/sh", "-c", "java -jar $JAVA_OPTS /hello.jar"]
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

# 创建java镜像文件
create_java_image(){
  docker image build -t java:v1 -f $homedir/Dockerfile $homedir/
  result=$?
  repository=`docker image ls | grep 'java' | awk '{print $1}'`
  tag=`docker image ls | grep 'java' | awk '{print $2}'`
  if [ $result -eq 0 -a "$repository"="java" -a "$tag"="v1" ];then
    echo -e "#########################################################"
    echo -e "###################java镜像文件创建成功!################"
    echo -e "#########################################################\n"
  else
    echo -e "#########################################################"
    echo -e "###################java镜像文件创建失败!################"
    echo -e "#########################################################\n"
  fi

}

# 通过java镜像文件创建容器
create_java_docker(){
 docker run -d --name java -m="256M" -h java java:v1
 result=$?
 cnt=`docker container ls -a | grep java | wc -l`
 if [ $result -eq 0 -a $cnt -eq 1 ];then
    echo -e "#########################################################"
    echo -e "#####################java容器创建成功!##################"
    echo -e "#########################################################\n"
 else
    echo -e "#########################################################"
    echo -e "#####################java容器创建失败!##################"
    echo -e "#########################################################\n"
 fi	 
}

# 创建java容器
install_java_docker(){
   check_docker
   check_pkg
   create_dockerfile
   create_java_image
   create_java_docker       
}

echo -e "#########################################################"
echo -e "####################java容器开始生成#####################"
echo -e "#########################################################\n"
install_java_docker
echo -e "#########################################################"
echo -e "####################java容器结束生成#####################"
echo -e "#########################################################\n"
