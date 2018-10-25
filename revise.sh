#!/bin/bash

#修改配置文件
sed -i "2a\\/**\n\n搭建问题可联系QQ209224407打赏解决\n\n*\/" /home/wwwroot/default/config/.config.php #插入
sed -i 's/1145141919810/209224407/g' /home/wwwroot/default/config/.config.php #替换
sed -i "s/NimaQu/marisn/g" /home/wwwroot/default/config/.config.php #替换
sed -i '35d' /home/wwwroot/default/config/.config.php #删除
sed -i "34a\$System_Config[\'db_password\'] = \'root\';				//数据库密码" /home/wwwroot/default/config/.config.php #插入
