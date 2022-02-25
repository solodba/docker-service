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
  if [ ! -f $homedir/swl_web.conf ];then
      echo -e "#########################################################"
      echo -e "####安装所需清单文件swl_web.conf不存在！退出安装！####"
      echo -e "#########################################################\n"
      exit 0
  else
      echo -e "#########################################################"
      echo -e "###############安装所需清单文件swl_web.conf存在!#############"
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
  done < $homedir/swl_web.conf
}

# 创建Dockerfile文件
create_tomcatweb_dockerfile(){
cat > $homedir/Dockerfile2 << "EOF"
FROM tomcat:v1
RUN rm -fr /usr/local/tomcat/webapps/*
COPY ROOT.war /usr/local/tomcat/webapps
EOF

# 判断文件是否创建成功
if [ -f $homedir/Dockerfile2 ];then
	echo -e "#########################################################"
	echo -e "###################Dockerfile2文件创建成功！##############"
	echo -e "#########################################################\n"
else
	echo -e "#########################################################"
        echo -e "###################Dockerfile2文件创建失败！##############"
        echo -e "#########################################################\n"
fi

}

# 创建tomcatweb镜像文件
create_tomcatweb_image(){
  docker image build -t tomcatweb:v1 -f $homedir/Dockerfile2 $homedir/
  result=$?
  repository=`docker image ls | grep 'tomcatweb' | awk '{print $1}'`
  tag=`docker image ls | grep 'tomcatweb' | awk '{print $2}'`
  if [ $result -eq 0 -a "$repository"="tomcatweb" -a "$tag"="v1" ];then
    echo -e "#########################################################"
    echo -e "###################tomcatweb镜像文件创建成功!############"
    echo -e "#########################################################\n"
  else
    echo -e "#########################################################"
    echo -e "###################tomcatweb镜像文件创建失败!############"
    echo -e "#########################################################\n"
  fi

}

# 通过tomcatweb镜像文件创建容器
create_tomcatweb_docker(){
 docker run -d -p 90:8080 --name web-tomcatweb -m="256M" -h tomcatweb tomcatweb:v1
 result=$?
 cnt=`docker container ls -a | grep web-tomcatweb | wc -l`
 if [ $result -eq 0 -a $cnt -eq 1 ];then
    echo -e "#########################################################"
    echo -e "#####################tomcatweb容器创建成功!##################"
    echo -e "#########################################################\n"
 else
    echo -e "#########################################################"
    echo -e "#####################tomcatweb容器创建失败!##################"
    echo -e "#########################################################\n"
 fi	 
}

# 创建tomcatweb容器
install_tomcatweb_docker(){
   check_docker
   check_pkg
   create_tomcatweb_dockerfile
   create_tomcatweb_image
   create_tomcatweb_docker       
}

echo -e "#########################################################"
echo -e "###################tomcatweb容器开始生成####################"
echo -e "#########################################################\n"
install_tomcatweb_docker
echo -e "#########################################################"
echo -e "###################tomcatweb容器结束生成####################"
echo -e "#########################################################\n"
