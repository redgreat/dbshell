#!/bin/bash
# mysqlbackup centos
# Generated: 2022-08-19 17:30:46
# every 30min increase backup crontab :
# */30 * * * * /opt/mysqlbak_binlog.sh
# reference @https://github.com/fradelg/docker-mysql-cron-backup / 

# 备份数据库账号需有SELECT,PROCESS,LOCK TABLES权限
# GRANT SELECT,PROCESS,LOCK TABLES *.* TO '$db_user'@'%';
# flush privileges;
# 安装必要工具
# rsync
# dnf -y install rsync

# 设置rsync免密登录
# 主机：ssh-keygen -t rsa -P ""
# ssh-copy-id root@备份机IP
# ssh -v root@备份机IP /bin/true
# rsync需开放端口873
#
# 备份目标可选
#  1,rsync到另一台linux;
#  2,samba挂载到备份机
#  3,上传至云服务
# 最好放在从库中去备份，可以防止主库在备份时的锁表

#备份服务器配置
bak_dir="/opt/mysql/logs"
bak_day=10
run_dir="/opt/mysqlbinbak"
bak_log=${run_dir}/mysqlbinbak.log
bak_time="$(date +%Y%m%d%H%M%S)"
#scp方式将备份文件传至远程地址配置
remote_ips="124.222.209.128"
remote_user="root"
remote_port=22
remote_dir="/opt/"
#samba目录
samba_dir=""
#备份文件上传至阿里OSS

#文件夹创建
if [ ! -d "$bak_dir" ]; then
mkdir -p $bak_dir
fi

if [ ! -d "$run_dir" ]; then
mkdir -p $run_dir
fi

if [ ! -f "$bak_log" ]; then
touch $bak_log
fi

fun_rm () {    
    echo $(date +'%Y-%m-%d %T')" ==> Start delete old binlog file:" >>${bak_log}
    find ${bak_dir} -type f -mtime +${bak_day} | tee delete_binlog_list.log | xargs rm -rf
    cat delete_binlog_list.log >>${bak_log}
    rm -rf delete_binlog_list.log
}

fun_tar () {    
    tar_file="binlog-$bak_time"
    echo $(date +'%Y-%m-%d %T')" ==> Start tar File: $tar_file" >>${bak_log}
    tar zcf "$tar_file".tar.gz $bak_dir/mysql-bin.* &> /dev/null
}

fun_rsync () {
    for remote_ip in ${remote_ips}
    do                
        echo $(date +'%Y-%m-%d %T')" ==> Srart rsync to $remote_ip" >>${bak_log}
        rsync -avz --progress --delete $run_dir -e "ssh -p "${remote_port}"" ${remote_user}@${remote_ip}:$remote_dir >>${bak_log} 2>&1
        echo $(date +'%Y-%m-%d %T')" ==> Success rsync to $remote_ip" >>${bak_log}
    done
    if [ ! -d "$samba_dir" ]; then 
        rsync -avz --progress --delete $run_dir $samba_dir >>${bak_log} 2>&1 
    fi
}

cd $run_dir

fun_rm
fun_tar
fun_rsync