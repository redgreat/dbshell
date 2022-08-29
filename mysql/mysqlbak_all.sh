#!/bin/bash
# mysqlbackup centos
# Generated: 2022-08-19 17:30:46
# 1:00 am every full backup crontab :
# 0 01 * * * * /opt/mysqlbak_all.sh
# reference @https://github.com/fradelg/docker-mysql-cron-backup / 

# 备份数据库账号需有SELECT,PROCESS,LOCK TABLES权限
# GRANT SELECT,PROCESS,LOCK TABLES *.* TO '$db_user'@'%';
# flush privileges;
# 安装必要工具
# mysql/mysqldump/rsync/jq
# dnf -y install mysql #注意mysql客户端版本
# dnf -y install holland-mysqldump.noarch
# dnf -y install rsync
# dnf -y install jq
#
# 设置rsync免密登录
# 主机：ssh-keygen -t rsa -P ""
# ssh-copy-id root@备份机IP
# ssh -v root@124.222.209.128 /bin/true
# rsync需开放端口873
#
# 备份目标可选
#  1,rsync到另一台linux;
#  2,samba挂载到备份机
#  3,上传至云服务

#备份服务器配置
db_host="10.16.1.58"
db_user="hammerdb"
db_pass="7574289"
db_port="3306"
bak_dir="/opt/mysqlbak"
bak_time="$(date +%Y%m%d)"
bak_day=7
bak_log=${bak_dir}/mysqlbak.log
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

if [ ! -f "$bak_log" ]; then
touch $bak_log
fi

fun_bak() {
dbs=`mysql -h$db_host -P$db_port -u$db_user -p$db_pass -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`
for db in ${dbs}
do
    if [[ "$db" != "information_schema" ]] \
        && [[ "$db" != "performance_schema" ]] \
        && [[ "$db" != "mysql" ]] \
        && [[ "$db" != "sys" ]] \
        && [[ "$db" != _* ]]
    then
        file_name="$db-$bak_time"
        dump_file=${bak_dir}${file_name}
        echo $(date +'%Y-%m-%d %T')" ==> Start Dumping database: $db" >>${bak_log}
        mysqldump -h${db_host} -u${db_user} -p${db_pass} --databases ${db} > ${dump_file}.sql 2>>${bak_log} 2>&1
        echo $(date +'%Y-%m-%d %T')" ==> Start zip file: ${file_name}.sql" >>${bak_log}
        tar zcf "$file_name".tar.gz "$dump_file".sql --remove &> /dev/null
        echo -e $(date +'%Y-%m-%d %T')" ==> Success backup database: "${db}" with file name: "${file_name}".tar.gz" >>${bak_log}
    fi
done
}

fun_rm() {    
    echo $(date +'%Y-%m-%d %T')" ==> Start delete backup file:" >>${bak_log}
    find ${bak_dir} -type f -mtime +${bak_day} | tee delete_list.log | xargs rm -rf
    cat delete_list.log >>${bak_log}
    rm -rf delete_list.log
}

fun_rsync() {
    for remote_ip in ${remote_ips}
    do                
        echo $(date +'%Y-%m-%d %T')" ==> Start rsync to Server:${remote_ip}" >>${bak_log} 
        rsync -avz --progress --delete $bak_dir -e "ssh -p "${remote_port}"" ${remote_user}@${remote_ip}:$remote_dir >>${bak_log} 2>&1
        echo $(date +'%Y-%m-%d %T')" ==> Success rsync to Server:${remote_ip}" >>${bak_log}
    done
    if [ ! -d "$samba_dir" ]; then 
        rsync -avz --progress --delete $bak_dir $samba_dir >>${bak_log} 2>&1 
    fi
}

fun_oss(){
    oss=$(curl -s http://fc.domain.com/upload2oss) #获取签名的json
    #echo $oss | python -m json.tool
    oss_startTime=`date +%s.%N`
    oss_dir=`echo $oss | jq .data.dir | sed \s/\"//g`
    oss_host=`echo $oss | jq .data.host | sed \s/\"//g`
    oss_policy=`echo $oss | jq .data.policy | sed \s/\"//g`
    oss_accessid=`echo $oss | jq .data.accessid | sed \s/\"//g`
    oss_signature=`echo $oss | jq .data.signature | sed \s/\"//g`

    curl -XPOST -sk ${oss_host} \
        -F "policy=${oss_policy}" \
        -F "Signature=${oss_signature}" \
        -F "success_action_status=200" \
        -F "OSSAccessKeyId=${oss_accessid}" \
        -F "x-oss-object-acl=public-read" \
        -F "key=${oss_dir}${1}" \
        -F "file=@${2}"

    oss_endTime=`date +%s.%N`
    oss_runTime=`echo $oss_endTime $oss_startTime | awk '{print $1-$2}'`
    oss_status=`curl -sI "${oss_host}/${oss_dir}${1}" | awk 'NR==1{print $2}'`

    if [ "${oss_status}"x == "200"x ]; then
        echo -e $(date +'%Y-%m-%d %T')" ==> File: ${2} Upload Success,URL: ${oss_host}/${oss_dir}${1} ,Cost: ${oss_runTime}s" >>${bak_log} 
    else
        echo $(date +'%Y-%m-%d %T')" ==> OSS file ${1} Upload failed: ${oss_status}" >>${bak_log} 
    fi
}

cd $bak_dir
fun_bak
fun_rm
fun_rsync

if [ ! -n "$oss" ]; then
    up_file=`ls *.tar.gz`
    for i in $up_file;
    do 
    fun_oss ${i##*/} ${i}
    done
fi    