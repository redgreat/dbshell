
rhel9安装部署mysql8

### 安装前准备
#### CRT连接
```
vim /etc/ssh/sshd_config
LoginGraceTime 0
PermitRootLogin yes
StrictModes yes
UseDNS no
MaxSessions 50

#重启 sshd 服务
systemctl restart sshd.service
```
#### 主机名、时区
```
timedatectl set-timezone "Asia/Shanghai" 
timedatectl status|grep Local
hostnamectl set-hostname rhel9
vim /etc/hostname
10.16.2.58 rhel9
```
#### 检查系统环境

```
#硬件
dmidecode |grep Name
#内存
dmidecode|grep -A5 "Memory Device"|grep Size|grep -v No |grep -v Range
#swap
grep SwapTotal /proc/meminfo | awk '{print $2}'
#内存大小
free -m
#磁盘空间
df -hT
```

#### 关闭防火墙&SElinux

```
systemctl stop firewalld.service          #停止firewall
systemctl disable firewalld.service        #禁止firewall开机启动
cp /etc/selinux/config /etc/selinux/config_`date +"%Y%m%d_%H%M%S"`&& sed -i 's/SELINUX\=enforcing/SELINUX\=disabled/g' /etc/selinux/config
cat /etc/selinux/config
#不重启
setenforce 0
getenforce
sestatus
```

#### 关闭透明大页
关闭透明大页（即 `Transparent Huge Pages`，缩写为 THP）。数据库的内存访问模式往往是稀疏的而非连续的。当高阶内存碎片化比较严重时，分配 THP 页面会出现较高的延迟。

```
cat /sys/kernel/mm/transparent_hugepage/enabled
# 执行 grubby 命令查看默认内核版本。
# grubby --default-kernel
/boot/vmlinuz-5.14.0-70.22.1.el9_0.x86_64
# 执行 grubby --update-kernel 命令修改内核配置
grubby --args="transparent_hugepage=never" --update-kernel /boot/vmlinuz-5.14.0-70.22.1.el9_0.x86_64
执行 grubby --info 命令查看修改后的默认内核配置。--info 后需要使用实际的默认内核版本。
grubby --info /boot/vmlinuz-5.14.0-70.22.1.el9_0.x86_64
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
#立即生效
cat /sys/kernel/mm/transparent_hugepage/enabled
cat /proc/cmdline
```

#### 关闭swap
DB 运行需要有足够的内存,如果内存充足，不建议使用 swap 作为内存不足的缓冲，因为这会降低性能,建议永久关闭系统 swap。

```
echo "vm.swappiness = 0">> /etc/sysctl.conf
swapoff -a && swapon -a
sysctl -p
vim /etc/fstab
# 注释加载swap分区的那行记录
#UUID=4f863b5f-20b3-4a99-a680-ddf84a3602a4 swap                    swap    defaults        0 0
```

#### 时钟同步
```
systemctl status chronyd.service
chronyc tracking

#结果是这个就正常
Leap status : Normal
```
如果要使 NTP 服务尽快开始同步，执行以下命令。可以将 pool.ntp.org 替换为你的 NTP 服务器：
```
sudo systemctl stop ntpd.service && \
sudo ntpdate pool.ntp.org && \
sudo systemctl start ntpd.service
```
如果要在 CentOS 7 系统上手动安装 NTP 服务，可执行以下命令：
```
sudo yum install ntp ntpdate && \
sudo systemctl start ntpd.service && \
sudo systemctl enable ntpd.service
```
#### 磁盘、I/O调度设置
将存储介质的 I/O 调度器设置为 noop。对于高速 SSD 存储介质，内核的 I/O 调度操作会导致性能损失。将调度器设置为 noop 后，内核不做任何操作，直接将 I/O 请求下发给硬件，以获取更好的性能。同时，noop 调度器也有较好的普适性。


```
# cat /sys/block/sda/queue/scheduler
[mq-deadline] kyber bfq none
```

```
1、查看CentOS6 CentOS7下IO支持的调度算法
#CentOS 6.x
#dmesg | grep -i scheduler
io scheduler noop registered
io scheduler anticipatory registered
io scheduler deadline registered
io scheduler cfq registered (default)
#CentOS 7.x
#dmesg | grep -i scheduler
[ 0.739263] io scheduler noop registered
[ 0.739267] io scheduler deadline registered (default)
[ 0.739315] io scheduler cfq registered
#rhel9
[    0.069059] rcu: RCU calculated value of scheduler-enlistment delay is 100 jiffies.
[    0.445431] io scheduler mq-deadline registered
[    0.446503] io scheduler kyber registered
[    0.447362] io scheduler bfq registered

2、查看设备当前的 I/O 调度器
#cat /sys/block//queue/scheduler
假设磁盘名称是 /dev/sda
#cat /sys/block/sda/queue/scheduler
noop [deadline] cfq
3、临时生效的方法
#cat /sys/block/sda/queue/scheduler
noop [deadline] cfq
#echo bfq>/sys/block/sda/queue/scheduler
#cat /sys/block/sda/queue/scheduler
noop deadline [cfq]
4、永久生效的方法
CentOS 7.x
#grubby --update-kernel=ALL --args="elevator=deadline"
#reboot
#cat /sys/block/sda/queue/scheduler
noop [deadline] cfq
或者使用vi编辑器修改配置文件，添加elevator= cfq
#vim /etc/default/grub
GRUB_CMDLINE_LINUX="crashkernel=auto rhgb quiet elevator=noop numa=off"
然后保存文件，重新编译配置文件
BIOS-Based： grub2-mkconfig -o /boot/grub2/grub.cfg
UEFI-Based： grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
```

#### CPU 频率模式设置
为调整 CPU 频率的 `cpufreq` 模块选用 `performance` 模式。将 CPU 频率固定在其支持的最高运行频率上，不进行动态调节，可获取最佳的性能。

```
cpupower frequency-info --policy
analyzing CPU 0:
  Unable to determine current policy
```
`The governor "powersave"` 表示 cpufreq 的节能策略使用 `powersave`，需要调整为 `performance` 策略。如果是虚拟机或者云主机，则不需要调整，命令输出通常为 `Unable to determine current policy`。此为虚拟机不需修改，如物理机

创建 CPU 节能策略配置服务。
```
cat  >> /etc/systemd/system/cpupower.service << EOF
[Unit]
Description=CPU performance
[Service]
Type=oneshot
ExecStart=/usr/bin/cpupower frequency-set --governor performance
[Install]
WantedBy=multi-user.target
EOF
```
应用 CPU 节能策略配置服务。
```
systemctl daemon-reload
systemctl enable cpupower.service
systemctl start cpupower.service
```

### 系统参数调整

`file-max` 中指定了系统范围内所有进程可打开的文件句柄的数量限制，在 MySQL 中很容易收到`”Too many open files in system”`这样的错误消息, 就应该增加这个值，这里由于测试环境设置为 100 万足够。
`net.core.somaxconn` 是 Linux 中的一个 `kernel` 参数，表示 `socket` 监听 (listen) 的 `backlog` 上限。什么是 `backlog` 呢？`backlog` 就是 `socket` 的监听队列，当一个请求 (request) 尚未被处理或建立时，他会进入 `backlog`。而 `socket server` 可以一次性处理 `backlog` 中的所有请求，处理后的请求不再位于监听队列中。当 server 处理请求较慢，以至于监听队列被填满后，新来的请求会被拒绝。
`net.ipv4.tcp_tw_recycle` 表示关闭启用 `TIME-WAIT` 状态 `sockets` 的快速回收，这个选项不推荐启用。在 `NAT(Network Address Translation)` 网络下，会导致大量的 TCP 连接建立错误。此值默认为 0，也是关闭状态，在 MySQL 的配置中有人也会开启此配置，这里在强调下。
`net.ipv4.tcp_syncookies` 表示关闭 `SYN Cookies`。默认为 0，表示关闭；如果开启时，当出现 SYN 等待队列溢出时，启用cookies 来处理，可防范少量 SYN 攻击，和 tcp\_tw\_recycle 一样，在 NAT 网卡模式下不建议开启此参数。
`vm.overcommit_memory` 文件指定了内核针对内存分配的策略，其值可以是 0、1、2。
0:(默认)表示内核将检查是否有足够的可用内存供应用进程使用；如果有足够的可用内存，内存申请允许；否则，内存申请失败，并把错误返回给应用进程。0 即是启发式的 `overcommitting handle`,会尽量减少 `swap` 的使用,root 可以分配比一般用户略多的内存。
1:表示内核允许分配所有的物理内存，而不管当前的内存状态如何，允许超过 `CommitLimit`，直至内存用完为止。
2:表示不允许超过 `CommitLimit` 值。
`limit.conf` 用于限制用户可以使用的最大文件数、最大线程、最大内存使用量，`soft` 是一个告警值，`hard` 则是一定意义上的阈值，一旦超过 `hard` ，系统就会报错

```
echo "fs.file-max = 1000000">> /etc/sysctl.conf
echo "net.core.somaxconn = 32768">> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_recycle = 0">> /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies = 0">> /etc/sysctl.conf
echo "vm.overcommit_memory = 1">> /etc/sysctl.conf

sysctl -p
```

```
cat << EOF >>/etc/security/limits.conf
db           soft    nofile          1000000
db           hard    nofile          1000000
db           soft    stack           32768
db           hard    stack           32768
EOF
```

### 安装前卸载
```
rpm -qa | grep -i mariadb
c

yum remove mariadb-libs
```

#删除用户/用户组
```
more /etc/passwd | grep mysql
more /etc/shadow | grep mysql
more /etc/group | grep mysql

groupdel mysql
userdel mysql
```

### 列出安装包明细
```
mysql-commercial-backup-8.0.30-1.1.el9.x86_64.rpm 备份
mysql-commercial-backup-debuginfo-8.0.30-1.1.el9.x86_64.rpm 调试组件
mysql-commercial-client-8.0.30-1.1.el9.x86_64.rpm 客户端
mysql-commercial-client-debuginfo-8.0.30-1.1.el9.x86_64.rpm 调试组件
mysql-commercial-client-plugins-8.0.30-1.1.el9.x86_64.rpm 插件
mysql-commercial-client-plugins-debuginfo-8.0.30-1.1.el9.x86_64.rpm 调试组件
mysql-commercial-common-8.0.30-1.1.el9.x86_64.rpm 公共文件
mysql-commercial-debuginfo-8.0.30-1.1.el9.x86_64.rpm 调试组件
mysql-commercial-devel-8.0.30-1.1.el9.x86_64.rpm 开发库
mysql-commercial-icu-data-files-8.0.30-1.1.el9.x86_64.rpm ICU
mysql-commercial-libs-8.0.30-1.1.el9.x86_64.rpm 共享库
mysql-commercial-libs-debuginfo-8.0.30-1.1.el9.x86_64.rpm 调试组件
mysql-commercial-server-8.0.30-1.1.el9.x86_64.rpm 服务端
mysql-commercial-server-debuginfo-8.0.30-1.1.el9.x86_64.rpm 调试组件
mysql-commercial-server-debug-8.0.30-1.1.el9.x86_64.rpm 服务端调试组件
mysql-commercial-server-debug-debuginfo-8.0.30-1.1.el9.x86_64.rpm 调试组件
mysql-commercial-test-8.0.30-1.1.el9.x86_64.rpm 测试组件
mysql-commercial-test-debuginfo-8.0.30-1.1.el9.x86_64.rpm 调试组件
mysql-router-commercial-8.0.30-1.1.el9.x86_64.rpm MySQL路由
mysql-router-commercial-debuginfo-8.0.30-1.1.el9.x86_64.rpm 调试组件
README.txt 更新说明
```

### 安装依赖包
```
dnf install net-tools -y
dnf install perl-Module-Build.noarch
```

### 安装rpm包（必要安装包）
```
rpm -ivh mysql-commercial-client-8.0.30-1.1.el9.x86_64.rpm \
mysql-commercial-client-plugins-8.0.30-1.1.el9.x86_64.rpm \
mysql-commercial-common-8.0.30-1.1.el9.x86_64.rpm \
mysql-commercial-icu-data-files-8.0.30-1.1.el9.x86_64.rpm \
mysql-commercial-libs-8.0.30-1.1.el9.x86_64.rpm \
mysql-commercial-server-8.0.30-1.1.el9.x86_64.rpm
```

### 验证MySQL是否安装成功
```
mysqladmin --version
cat /etc/passwd|grep mysql
cat /etc/group|grep mysql
usermod mysql -m -g mysql -s /bin/bash -d /home/mysql

rpm -qa | grep -i mysql
```

### 服务状态

```
systemctl status mysqld
systemctl start mysqld
systemctl stop mysqld
systemctl restart mysqld

设置开机自启动：
systemctl enable mysqld
chkconfig --list | grep mysql
systemctl list-unit-files
```

### 初始化

#### 因MySQL 8.0在Linux下库表名默认区分大小写，且只能在初始化时指定不能修改，现直接修改初始化配置文件避免重新初始化

mysqld --initialize --user=mysql --lower-case-table-names=1 --datadir=/opt/mysql/data/

#查看初始密码
cat /var/log/mysqld.log | grep password
#报错
##文件打不开
cp /usr/share/mysql-8.0/english/errmsg.sys /usr/share/mysql-8.0/errmsg.sys
##socket文件打不开
mkdir -p /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql

### 创建用户

```
## 先设置密码，例如：Mysql@123，注意密码为高安保等级（例如大小写和特殊字符的组合），不然无法使用其他操作
ALTER USER 'root'@'localhost' IDENTIFIED BY '你的密码';
## 看当前所有数据库
show databases;
## 进入mysql库
use mysql;
## 查看当前默认规则：
show variables like 'validate_password%';
## 修改校验密码策略等级:LOW，默认为：MEDIUM
set global validate_password.policy=LOW;
## 设置密码长度至少为 6，默认为8；
set global validate_password.length=6;
## 立即生效
flush privileges;
## 查看用户信息
select host, user, authentication_string, plugin from user;
# 更新root信息
update user set host='%' where user='root';
# 授权root用户可以远程登陆
GRANT ALL ON *.* TO 'root'@'%';
## 远程连接设置
ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '你的密码'; 
## 立即生效
flush privileges;

```



