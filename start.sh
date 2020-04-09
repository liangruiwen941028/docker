#!/bin/bash
#./del.sh 做测试时候使用 删除全部容器
mysql_user="mydb_slave_user"    # 主服务器允许从服务器登录的用户名
mysql_password="mydb_slave_pwd" # 主服务器允许从服务器登录的密码
root_password="123456"             # 每台服务器的root密码

master_container=master
slave_containers=node
leibiao=("$master_container" "$slave_containers")

if [ ! -d './mysql_master' ];then
   mkdir ./mysql_master
fi

if [ ! -d './mysql_node' ];then
   mkdir ./mysql_node
fi

#for i in ${leibiao[*]};
#do
#   echo $i
#done

docker-compose up -d
#sleep 30
for container in ${leibiao[*]};
do
 until docker exec $container sh -c 'export MYSQL_PWD='$root_password'; mysql -u root -e ";"'
 do    
      echo "$container 启动中,连接中,请稍候,每3s 尝试连接一次,可能会重试多次,直到容器启动完毕....."
      sleep 3
 done 
done


#获取主库的IP地址
ip=`docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $master_container`

#################### 主服务器操作 ####################开始
# 在主服务器上添加数据库用户
priv_stmt='GRANT REPLICATION SLAVE ON *.* TO "'$mysql_user'"@"%" IDENTIFIED BY "'$mysql_password'"; FLUSH PRIVILEGES;'

docker exec $master_container sh -c "export MYSQL_PWD='$root_password'; mysql -u root -e '$priv_stmt'"

# 查看主服务器的状态
MS_STATUS=`docker exec $master_container sh -c 'export MYSQL_PWD='$root_password'; mysql -u root -e "SHOW MASTER STATUS"'`

# binlog文件名字,对应 File 字段,值如: mysql-bin.000004

CURRENT_LOG=`echo $MS_STATUS | awk '{print $6}'`
#echo $CURRENT_LOG
# binlog位置,对应 Position 字段,值如: 1429
CURRENT_POS=`echo $MS_STATUS | awk '{print $7}'`
#echo $CURRENT_POS

#################### 从服务器操作 ####################开始
# 设置从服务器与主服务器互通命令
start_slave_stmt="CHANGE MASTER TO
        MASTER_HOST='$ip',
        MASTER_USER='$mysql_user',
        MASTER_PASSWORD='$mysql_password',
        MASTER_LOG_FILE='$CURRENT_LOG',
        MASTER_LOG_POS=$CURRENT_POS;"
#start_slave_cmd='export MYSQL_PWD='$root_password'; mysql -u root -e "'
start_slave_cmd=' mysql -u root -p123456 -e "'
start_slave_cmd+="$start_slave_stmt"
start_slave_cmd+='START SLAVE;"'
#echo $start_slave_cmd

docker exec $slave_containers sh -c "$start_slave_cmd"
docker exec $slave_containers sh -c "export MYSQL_PWD='$root_password'; mysql -u root -e 'SHOW SLAVE STATUS \G'"
