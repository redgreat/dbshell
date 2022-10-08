#端口号查询

lsof -nP -iTCP -sTCP:LISTEN 

#linux下获取占用CPU资源最多的10个进程，可以使用如下命令组合：

ps aux|head -1;ps aux|sort -rn -k +3|head

#linux下获取占用内存资源最多的10个进程，可以使用如下命令组合：

ps aux|head -1;ps aux|sort -rn -k +4|head

#head 默认获取10行，可以在后面加 -n 控制显示数量，如获取三行

ps aux|head -1;ps aux|sort -rn -k +3|head -3

#安装Docker
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
#启动
systemctl start docker
#查看docker内容器
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}\t{{.Status}}"
#查询镜像
docker search mongo
#查看镜像版本
curl https://registry.hub.docker.com/v1/repositories/${docker_img}/tags | python3 -m json.tool | more
#查看版本/基本信息
docker -v
docker info
#拉取镜像
docker pull apache/incubator-doris:build-env-1.2
#查看已下载镜像
docker images
#删除镜像
docker rmi apache/incubator-doris:build-env-1.2
#查看容器
docker container ls -all
#查看容器运行状态，相当于top
docker stats
#开启容器
docker start doris-014
#关闭容器
docker stop doris-014
#重启容器
docker restart doris-014
#删除容器
docker rm doris-014
#连接容器(正在运行)
docker attach doris-014
#连接容器(正在运行)
docker exec -it 容器ID /bin/bash
## alpine linux
docker exec -it 容器ID /bin/sh
#退出（默认直接关闭）
exit
#删除所有容器
docker rm $(docker ps -a -q)
#删除所有镜像
docker rmi $(docker images -q)
#清理docker磁盘
docker system prune -a
#搜索镜像
dock search elasticsearch
#查看镜像版本
curl https://registry.hub.docker.com/v1/repositories/elasticsearch/tags| tr -d '[\[\]" ]' | tr '}' '\n'| awk -F: -v image='elasticsearch' '{if(NR!=NF && $3 != ""){printf("%s:%s\n",image,$3)}}'
#查看挂在目录
docker volume ls
docker volume inspect

#查看volumes目录大小
du -sh /var/lib/docker/volumes/
#清理volumes目录下不同的volume
docker volume ls -f dangling=true | awk '{ print $2 }' | xargs docker volume rm

#查看清理后的volumes目录大小
#/var/lib/docker/tmp清理
#有一次制作镜像，一口气后台制作8个镜像，结果，tmp目录瞬间涨到12G。虚机硬盘分配的空间不大，导致了磁盘爆满，还好能直接删除tmp目录下所有的文件目录。

#容器清理
sudo docker ps --filter status=dead --filter status=exited -aq | xargs -r sudo docker rm -v

#镜像清理
sudo docker images --no-trunc | grep '<none>' | awk '{ print $3 }' | xargs -r sudo docker rmi
#查看所有docker存储卷
sudo docker system df
docker system prune
docker system prune -a

#删除所有关闭的容器：
docker ps -a | grep Exit | cut -d ' ' -f 1 | xargs docker rm

#删除所有dangling镜像（即无tag的镜像）：
docker rmi $(docker images | grep "^<none>" | awk "{print $3}")

#删除所有dangling数据卷（即无用的Volume）：
docker volume rm $(docker volume ls -qf dangling=true)

#docker镜像自动更新
docker pull containrrr/watchtower
$ docker run -d \
 --name watchtower \
 -v /var/run/docker.sock:/var/run/docker.sock \
 containrrr/watchtower \
 --cleanup \
 --schedule "0 0 4 * * *" \
 --include-restarting
  
#查看docker日志
docker logs --tail=1000 容器名称
docker-compose -f docker-compose-app.yml logs -f
docker compose -f docker-compose.yml logs -f

#启动镜像
docker-compose up -d
#关闭
docker-compose down

# 关闭原有服务
docker compose down
# 删除原有镜像
docker rmi mereith/van-blog:latest
# 重新拉取最新镜像
docker pull mereith/van-blog:latest
# 重新启动服务
docker compose up -d

#安装jdk

wget https://repo.huaweicloud.com/java/jdk/8u202-b08/jdk-8u202-linux-x64.tar.gz
mkdir -pv /usr/jdk1.8.0_202/ && tar -zxvf jdk-8u202-linux-x64.tar.gz -C /usr/
vim /etc/profile
#添加
JAVA_HOME=/usr/jdk1.8.0_202
CLASSPATH=.:$JAVA_HOME/lib.tools.jar
PATH=$JAVA_HOME/bin:$PATH
export JAVA_HOME CLASSPATH PATH
#生效
source /etc/profile

#编译安装软件常用包批量安装
yum groupinstall "Development Libraries"
yum groupinstall "Development Tools"

#scp拷贝文件
scp -P9998 6gbI3wHG_root@118.178.228.90:/root/datax.tar.gz /opt/

#查看磁盘
fdisk -l
df -hT
du -h --max-depth=1 *

#安装主题
npm install --save hexo-deployer-git
git clone -b master https://github.com/dhjddcn/halo-theme-butterfly.git themes/butterfly

#重置全局代理
git config --global --unset https.proxy
git config --global --unset http.proxy
git config --global http.proxy socks5://127.0.0.1:7890
git config --global http.https://github.com.proxy socks5://127.0.0.1:7890


mysql -h127.0.0.1 -P9766 -upolardbx_root -pvvGhDrIh

systemctl start docker

#更新PVE源
echo "#deb https://enterprise.proxmox.com/debian/pve bullseye pve-enterprise" > /etc/apt/sources.list.d/pve-enterprise.list

wget https://mirrors.ustc.edu.cn/proxmox/debian/proxmox-release-bullseye.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bullseye.gpg
echo "deb https://mirrors.ustc.edu.cn/proxmox/debian/pve bullseye pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list     #中科大源
echo "deb https://mirrors.ustc.edu.cn/proxmox/debian/ceph-pacific bullseye main" > /etc/apt/sources.list.d/ceph.list     #中科大源
sed -i.bak "s#http://download.proxmox.com/debian#https://mirrors.ustc.edu.cn/proxmox/debian#g" /usr/share/perl5/PVE/CLI/pveceph.pm     #中科大源
apt update && apt dist-upgrade     #更新软件，可不执行

sed -i.bak "s#ftp.debian.org/debian#mirrors.aliyun.com/debian#g" /etc/apt/sources.list     #阿里Debian源
sed -i "s#security.debian.org#mirrors.aliyun.com/debian-security#g" /etc/apt/sources.list     #阿里Debian源
apt update && apt dist-upgrade     #更新软件，可不执行

sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service
# 执行完成后，浏览器Ctrl+F5强制刷新缓存

# 新建用户组
groupadd hauser
# 新建用户并加入用户组  
# -m 自动创建用户主目录 
# -g 加入用户组
# -s 用户的登录shell
# -d 用户主目录
useradd hauser -m -g hausers -s /bin/bash -d /home/hauser
# 设置密码
passwd hauser
# 设置用户允许使用sudo
/sbin/usermod -aG sudo hauser
# 切换用户
su -l hauser

## v2Ray 操作指令
v2ray info 查看 V2Ray 配置信息
v2ray config 修改 V2Ray 配置
v2ray link 生成 V2Ray 配置文件链接
v2ray infolink 生成 V2Ray 配置信息链接
v2ray qr 生成 V2Ray 配置二维码链接
v2ray ss 修改 Shadowsocks 配置
v2ray ssinfo 查看 Shadowsocks 配置信息
v2ray ssqr 生成 Shadowsocks 配置二维码链接
v2ray status 查看 V2Ray 运行状态
v2ray start 启动 V2Ray
v2ray stop 停止 V2Ray
v2ray restart 重启 V2Ray
v2ray log 查看 V2Ray 运行日志
v2ray update 更新 V2Ray
v2ray update.sh 更新 V2Ray 管理脚本
v2ray uninstall 卸载 V2Ray

9ecd7f1ac0b7a1fef65e6b2148696918a1e13d38
+ixGlHpUN+Ah0TOAKosGUeD+etNvdtQ/mUg7BodkQQo=
9**