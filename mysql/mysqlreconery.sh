#!/bin/bash
# mysqlrecovery centos
# auther: wangcw
# Generated: 2022-08-19 17:33:35

db_host=""
db_user=""
db_pass=""
db_name="callcenter"
db_table="cdr"
bak_cmd=`which mysqldump | head -n 1`
bak_dir="/opt/calldataetl/sqldata/"
bak_time="$(date +%Y%m%d)"
file_name=mvb2000cdrdb-"$bak_time"
wget_cmd=`which wget | head -n 1`
wget_url=""

if [ ! -n "$bak_cmd" ]; then
yum -y install holland-mysqldump.noarch
bak_cmd=`which mysqldump | head -n 1`
fi

if [ ! -n "$wget_cmd" ]; then
yum -y install wget
wget_cmd=`which wget | head -n 1`
fi

if [ ! -d "$bak_dir" ]; then
mkdir -p $bak_dir
fi
cd $bak_dir
rm -rf *

"$wget_cmd" "$wget_url""$file_name".tar.gz
tar -zxf $file_name.tar.gz

mysql -h"$db_host" -u"$db_user" -p"$db_pass" --database "$db_name" < "$file_name".sql

rm -rf "$file_name".tar.gz
rm -rf *.sql
