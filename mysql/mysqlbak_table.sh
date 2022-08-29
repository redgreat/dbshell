#!/bin/bash
# mysqlbackup centos
# Generated: 2022-08-19 17:30:46

# 提供的数据库账号需有PROCESS权限
# GRANT PROCESS ON *.* TO '$db_user'@'localhost';
# flush privileges;

db_host=""
db_user=""
db_pass=""
db_name=""
db_table=""
db_filter="calldate >= DATE_ADD(CURDATE(),INTERVAL -1 DAY) AND calldate < CURDATE()"
bak_cmd=`which mysqldump | head -n 1`
bak_dir="/backup"
bak_time="$(date +%Y%m%d)"
file_name="$db_name-$bak_time"

if [ ! -n "$bak_cmd" ]; then
yum -y install holland-mysqldump.noarch
bak_cmd=`which mysqldump | head -n 1`
fi

if [ ! -d "$bak_dir" ]; then
mkdir -p /backup
fi
cd $bak_dir
rm -rf *

"$bak_cmd" -h"$db_host" -u"$db_user" -p"$db_pass" \
--databases "$db_name" --tables "$db_table" \
--no-create-db --no-create-info --replace \
--max_allowed_packet=1024000 \
--where "$db_filter" > "$file_name".sql
tar zcf "$file_name".tar.gz "$file_name".sql --remove &> /dev/null


