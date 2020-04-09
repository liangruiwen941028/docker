#del.sh  测试时候方便删除完全容器   
#docker-compose.yml   docker-compose容器启动文件
#master_my.cnf  主库的配置文件
#node_my.cnf    从库的配置文件
#start.sh       一键式安装运行脚本

镜像使用的是5.7版本的数据库
运行方式 ./start 运行这个脚本



进入容器
#docker exec -it master /bin/bash  进入主库容器
#docker exec -it node /bin/bash    进入从库容器

进入数据库mysql -uroot -p123456
主库查看状态
SHOW MASTER STATUS；

从库查看同步结果
SHOW SLAVE STATUS;

状态里面这2个是yes 就是没问题
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
