#ss-panel-v3-mod_UIChanges
#Author: 十一
#Blog: blog.67cc.cn
#Time：2018-8-25 11:05:33
#!/bin/bash

#check root
[ $(id -u) != "0" ] && { echo "Error: You must run this script as root"; exit 1; }
function check_system(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
	if [[ ${release} == "centos" ]] && [[ ${bit} == "x86_64" ]]; then
	echo -e "Your system is[${release} ${bit}],Detection${Green} can ${Font}Build."
	else 
	echo -e "Your system is[${release} ${bit}],Detection${Red} not can ${Font}Build."
	echo -e "${Yellow} Exiting script... ${Font}"
	exit 0;
	fi
}
function install_ss_panel_mod_UIm(){
    yum remove httpd -y
	yum install unzip zip git -y
	wget -c --no-check-certificate https://raw.githubusercontent.com/marisn2017/ss-panel-v3-mod_Uim/master/lnmp1.5.zip && unzip lnmp1.5.zip && rm -rf lnmp1.5.zip && cd lnmp1.5 && chmod +x install.sh && ./install.sh lnmp
	cd /home/wwwroot/
	cp -r default/phpmyadmin/ .  #Copy database
	cd default
	rm -rf index.html
	yum update nss curl iptables -y
	#Cloning project
	git clone https://github.com/marisn2017/ss-panel-v3-mod_Uim-resource.git tmp && mv tmp/.git . && rm -rf tmp && git reset --hard
	#Copy configuration file
	# cp config/.config.php.example config/.config.php
	#Remove anti-cross-site attacks(open_basedir)
	cd /home/wwwroot/default
	chattr -i .user.ini
	rm -rf .user.ini
	sed -i 's/^fastcgi_param PHP_ADMIN_VALUE/#fastcgi_param PHP_ADMIN_VALUE/g' /usr/local/nginx/conf/fastcgi.conf
    /etc/init.d/php-fpm restart
    /etc/init.d/nginx reload
	#Set file permissions
	chown -R root:root *
	chmod -R 777 *
	chown -R www:www storage
	#Download configuration file
	wget -N -P  /usr/local/nginx/conf/ --no-check-certificate "https://raw.githubusercontent.com/marisn2017/ss-panel-v3-mod_Uim/master/nginx.conf"
	wget -N -P /usr/local/php/etc/ --no-check-certificate "https://raw.githubusercontent.com/marisn2017/ss-panel-v3-mod_Uim/master/php.ini"
	#Turn on the scandir() function
	sed -i 's/,scandir//g' /usr/local/php/etc/php.ini
	service nginx restart #Restart Nginx
	# mysql -uroot -proot -e"create database sspanel;" 
	# mysql -uroot -proot -e"use sspanel;" 
	# mysql -uroot -proot sspanel < /home/wwwroot/default/sql/sspanel.sql
	mysql -hlocalhost -uroot -proot <<EOF
create database sspanel;
use sspanel;
source /home/wwwroot/default/sql/sspanel.sql;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;
flush privileges;
EOF
	cd /home/wwwroot/default
	#Install composer
	php composer.phar install
	mv tool/alipay-f2fpay vendor/
	mv -f tool/cacert.pem vendor/guzzle/guzzle/src/Guzzle/Http/Resources/
	#mv -f tool/autoload_classmap.php vendor/composer/
	wget -N -P  /home/wwwroot/default/vendor/composer --no-check-certificate "https://raw.githubusercontent.com/marisn2017/ss-panel-v3-mod_Uim/master/autoload_classmap.php"
	php xcat syncusers            #Synchronize users
	php xcat initQQWry            #Download IP Resolution Library
	php xcat resetTraffic         #Reset traffic
	php xcat initdownload         #Download ssr program
	#Create monitoring
	yum -y install vixie-cron crontabs
	rm -rf /var/spool/cron/root
	echo 'SHELL=/bin/bash' >> /var/spool/cron/root
	echo 'PATH=/sbin:/bin:/usr/sbin:/usr/bin' >> /var/spool/cron/root
	echo '*/20 * * * * /usr/sbin/ntpdate pool.ntp.org > /dev/null 2>&1' >> /var/spool/cron/root
	echo '0 0 * * * php -n /home/wwwroot/default/xcat dailyjob' >> /var/spool/cron/root
	echo '*/1 * * * * php /home/wwwroot/default/xcat checkjob' >> /var/spool/cron/root
	echo "*/1 * * * * php /home/wwwroot/default/xcat syncnode" >> /var/spool/cron/root
	echo '30 22 * * * php /home/wwwroot/default/xcat sendDiaryMail' >> /var/spool/cron/root
	/sbin/service crond restart
	if [ -d "/home/wwwroot/default/" ];then
	clear
	echo "${Green}ss-panel-v3-mod_UIChanges installed successfully~${Font}"
	else
	echo "${Red}Installation failed, please reload the grid~${Font}"
	fi
}

function Libtest(){
	#Automatically select download nodes
	GIT='raw.githubusercontent.com'
	LIB='download.libsodium.org'
	GIT_PING=`ping -c 1 -w 1 $GIT|grep time=|awk '{print $7}'|sed "s/time=//"`
	LIB_PING=`ping -c 1 -w 1 $LIB|grep time=|awk '{print $7}'|sed "s/time=//"`
	echo "$GIT_PING $GIT" > ping.pl
	echo "$LIB_PING $LIB" >> ping.pl
	libAddr=`sort -V ping.pl|sed -n '1p'|awk '{print $2}'`
	if [ "$libAddr" == "$GIT" ];then
		libAddr='https://raw.githubusercontent.com/marisn2017/ss-panel-v3-mod_Uim/master/libsodium-1.0.17.tar.gz'
	else
		libAddr='https://download.libsodium.org/libsodium/releases/libsodium-1.0.17.tar.gz'
	fi
	rm -f ping.pl		
}
function Get_Dist_Version()
{
    if [ -s /usr/bin/python3 ]; then
        Version=`/usr/bin/python3 -c 'import platform; print(platform.linux_distribution()[1][0])'`
    elif [ -s /usr/bin/python2 ]; then
        Version=`/usr/bin/python2 -c 'import platform; print platform.linux_distribution()[1][0]'`
    fi
}
function python_test(){
	#Speed measurement determines which source to use
	tsinghua='pypi.tuna.tsinghua.edu.cn'
	pypi='mirror-ord.pypi.io'
	doubanio='pypi.doubanio.com'
	pubyun='pypi.pubyun.com'	
	tsinghua_PING=`ping -c 1 -w 1 $tsinghua|grep time=|awk '{print $8}'|sed "s/time=//"`
	pypi_PING=`ping -c 1 -w 1 $pypi|grep time=|awk '{print $8}'|sed "s/time=//"`
	doubanio_PING=`ping -c 1 -w 1 $doubanio|grep time=|awk '{print $8}'|sed "s/time=//"`
	pubyun_PING=`ping -c 1 -w 1 $pubyun|grep time=|awk '{print $8}'|sed "s/time=//"`
	echo "$tsinghua_PING $tsinghua" > ping.pl
	echo "$pypi_PING $pypi" >> ping.pl
	echo "$doubanio_PING $doubanio" >> ping.pl
	echo "$pubyun_PING $pubyun" >> ping.pl
	pyAddr=`sort -V ping.pl|sed -n '1p'|awk '{print $2}'`
	if [ "$pyAddr" == "$tsinghua" ]; then
		pyAddr='https://pypi.tuna.tsinghua.edu.cn/simple'
	elif [ "$pyAddr" == "$pypi" ]; then
		pyAddr='https://mirror-ord.pypi.io/simple'
	elif [ "$pyAddr" == "$doubanio" ]; then
		pyAddr='http://pypi.doubanio.com/simple --trusted-host pypi.doubanio.com'
	elif [ "$pyAddr" == "$pubyun_PING" ]; then
		pyAddr='http://pypi.pubyun.com/simple --trusted-host pypi.pubyun.com'
	fi
	rm -f ping.pl
}
# Add SS-panel nodes with one click
function install_centos_ssr(){
	cd /root
	Get_Dist_Version
	if [ $Version == "7" ]; then
		wget --no-check-certificate https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm 
		rpm -ivh epel-release-latest-7.noarch.rpm	
	else
		wget --no-check-certificate https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
		rpm -ivh epel-release-latest-6.noarch.rpm
	fi
	rm -rf *.rpm
	yum -y update --exclude=kernel*	
	yum -y install git gcc python-setuptools lsof lrzsz python-devel libffi-devel openssl-devel iptables
	yum -y update nss curl libcurl 
	yum -y groupinstall "Development Tools" 
	#First yum installation supervisor pip
	yum -y install supervisor python-pip
	supervisord
	#Whether the second pip supervisor is successfully installed
	if [ -z "`pip`" ]; then
    curl -O https://bootstrap.pypa.io/get-pip.py
		python get-pip.py 
		rm -rf *.py
	fi
	if [ -z "`ps aux|grep supervisord|grep python`" ]; then
    pip install supervisor
    supervisord
	fi
	#Whether the third Detectionpip supervisor is successfully installed
	if [ -z "`pip`" ]; then
		if [ -z "`easy_install`"]; then
    wget http://peak.telecommunity.com/dist/ez_setup.py
		python ez_setup.py
		fi		
		easy_install pip
	fi
	if [ -z "`ps aux|grep supervisord|grep python`" ]; then
    easy_install supervisor
    supervisord
	fi
	pip install --upgrade pip
	Libtest
	wget --no-check-certificate $libAddr
	tar xf libsodium-1.0.17.tar.gz && cd libsodium-1.0.17
	./configure && make -j2 && make install
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
	#Clean up files
	cd /root && rm -rf libsodium*
	git clone -b manyuser https://github.com/NimaQu/shadowsocks.git "/root/shadowsocks"
	cd /root/shadowsocks
	chkconfig supervisord on
	#First installation
	python_test
	pip install -r requirements.txt -i $pyAddr	
	#Whether the second detection is successfully installed
	if [ -z "`python -c 'import requests;print(requests)'`" ]; then
		pip install -r requirements.txt #Try to install it again with your own source.
	fi
	#Whether the third detection is successful
	if [ -z "`python -c 'import requests;print(requests)'`" ]; then
	    cd /root && mkdir python && cd python
		git clone https://github.com/shazow/urllib3.git && cd urllib3
		python setup.py install && cd ..
		git clone https://github.com/nakagami/CyMySQL.git && cd CyMySQL
		python setup.py install && cd ..
		git clone https://github.com/requests/requests.git && cd requests
		python setup.py install && cd ..
		git clone https://github.com/pyca/pyopenssl.git && cd pyopenssl
		python setup.py install && cd ..
		git clone https://github.com/cedadev/ndg_httpsclient.git && cd ndg_httpsclient
		python setup.py install && cd ..
		git clone https://github.com/etingof/pyasn1.git && cd pyasn1
		python setup.py install && cd ..
		rm -rf python
	fi	
	systemctl stop firewalld.service
	systemctl disable firewalld.service
	cd /root/shadowsocks
	cp apiconfig.py userapiconfig.py
	cp config.json user-config.json
}
function install_ubuntu_ssr(){
	apt-get update -y
	apt-get install supervisor lsof -y
	apt-get install build-essential wget -y
	apt-get install iptables git -y
	Libtest
	wget --no-check-certificate $libAddr
	tar xf libsodium-1.0.17.tar.gz && cd libsodium-1.0.17
	./configure && make -j2 && make install
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
	apt-get install python-pip git -y
	pip install cymysql
	cd /root
	git clone -b manyuser https://github.com/NimaQu/shadowsocks.git "/root/shadowsocks"
	cd shadowsocks
	pip install -r requirements.txt
	chmod +x *.sh
	# Configuration program
	cp apiconfig.py userapiconfig.py
	cp config.json user-config.json
}

function install_node(){
	clear
	#Check Root
	[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }
	#check OS version
	check_sys(){
		if [[ -f /etc/redhat-release ]]; then
			release="centos"
		elif cat /etc/issue | grep -q -E -i "debian"; then
			release="debian"
		elif cat /etc/issue | grep -q -E -i "ubuntu"; then
			release="ubuntu"
		elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
			release="centos"
		elif cat /proc/version | grep -q -E -i "debian"; then
			release="debian"
		elif cat /proc/version | grep -q -E -i "ubuntu"; then
			release="ubuntu"
		elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
			release="centos"
	  fi
	}
	install_ssr_for_each(){
		check_sys
		if [[ ${release} = "centos" ]]; then
			install_centos_ssr
		else
			install_ubuntu_ssr
		fi
	}
	# Cancel file limit
	sed -i '$a * hard nofile 512000\n* soft nofile 512000' /etc/security/limits.conf
	echo -e "If the following manual configuration error, please manually edit the changes in ${config}"
	read -p "Please enter your docking domain name or IP (for example: http://www.baidu.com If you are the machine, please press Enter): " WEBAPI_URL
	read -p "Please enter muKey (in your configuration file, if it is this machine, please press Enter):" WEBAPI_TOKEN
	read -p "Please enter the speed measurement cycle (the default is to test the speed every 6 hours):" SPEEDTEST
	read -p "Please enter your node number (very important, must be filled, can't enter):" NODE_ID
	install_ssr_for_each
	IPAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
	cd /root/shadowsocks
	echo -e "modify Config.py...\n"
	WEBAPI_URL=${WEBAPI_URL:-"http://${IPAddress}"}
	sed -i '/WEBAPI_URL/c \WEBAPI_URL = '\'${WEBAPI_URL}\''' ${config}
	#sed -i "s#https://zhaoj.in#${WEBAPI_URL}#" /root/shadowsocks/userapiconfig.py
	WEBAPI_TOKEN=${WEBAPI_TOKEN:-"marisn"}
	sed -i '/WEBAPI_TOKEN/c \WEBAPI_TOKEN = '\'${WEBAPI_TOKEN}\''' ${config}
	#sed -i "s#glzjin#${WEBAPI_TOKEN}#" /root/shadowsocks/userapiconfig.py
	SPEEDTEST=${SPEEDTEST:-"6"}
	sed -i '/SPEED/c \SPEEDTEST = '${SPEEDTEST}'' ${config}
	NODE_ID=${NODE_ID:-"3"}
	sed -i '/NODE_ID/c \NODE_ID = '${NODE_ID}'' ${config}
	#sed -i '2d' /root/shadowsocks/userapiconfig.py
	#sed -i "2a\NODE_ID = ${NODE_ID}" /root/shadowsocks/userapiconfig.py
	# 启用supervisord守护
	supervisorctl shutdown
	#某些机器没有echo_supervisord_conf
	wget -N -P  /etc/ --no-check-certificate  https://raw.githubusercontent.com/marisn2017/ss-panel-v3-mod_Uim/master/supervisord.conf	
	supervisord
	#iptables
	iptables -F
	iptables -X  
	iptables -I INPUT -p tcp -m tcp --dport 22:65535 -j ACCEPT
	iptables -I INPUT -p udp -m udp --dport 22:65535 -j ACCEPT
	iptables-save >/etc/sysconfig/iptables
	echo 'iptables-restore /etc/sysconfig/iptables' >> /etc/rc.local
	echo "/usr/bin/supervisord -c /etc/supervisord.conf" >> /etc/rc.local
	chmod +x /etc/rc.d/rc.local
	echo "#############################################################"
	echo "#          The installation is complete, the node is about to restart and the configuration takes effect.                 #"
	echo "#############################################################"
	reboot now
}
function install_BBR(){
     wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh&&chmod +x bbr.sh&&./bbr.sh
}
function install_RS(){
     wget -N --no-check-certificate https://github.com/91yun/serverspeeder/raw/master/serverspeeder.sh && bash serverspeeder.sh
}
function NEW_NODE(){
     wget -N --no-check-certificate  https://raw.githubusercontent.com/marisn2017/ss-panel-v3-mod_Uim/master/node.sh && bash node.sh
}

#Conventional variable
update_time="2018年11月10日21:14:00"
config="/root/shadowsocks/userapiconfig.py"

#fonts color
Green="\033[32m" 
Red="\033[31m" 
Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"

#notification information
Info="${Green}[Info]${Font}"
OK="${Green}[OK]${Font}"
Error="${Red}[Error]${Font}"
Notification="${Yellow}[Notification]${Font}"

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
ulimit -c 0
rm -rf script*
clear
check_system
sleep 2
echo -e "Last updated script:${Green} ${update_time} ${Font}"
echo -e "\033[31m#############################################################\033[0m"
echo -e "\033[32m#Welcome to the one-click ss-panel-v3-mod_UIChanges build script and node add #\033[0m"
echo -e "\033[34m#Blog: http://blog.67cc.cn/                                 #\033[0m"
echo -e "\033[35m#Please select the script you want to build:                                     #\033[0m"
echo -e "\033[36m#1.  One-click ss-panel-v3-mod_UIChanges to build                      #\033[0m"
echo -e "\033[31m#2.  Add SS-panel node with one click [new version]                             #\033[0m"
echo -e "\033[36m#3.  Add SS-panel nodes with one click                                   #\033[0m"
echo -e "\033[35m#4.  One-click BBR acceleration build                                    #\033[0m"
echo -e "\033[34m#5.  One-click sharp crack version build                                     #\033[0m"
echo -e "\033[33m#                                PS: It is recommended to build an acceleration and then build the panel.#\033[0m"
echo -e "\033[32m#                                   Support for Centos 7.x systems#\033[0m"
echo -e "\033[31m#############################################################\033[0m"
echo
read num
if [[ $num == "1" ]]
then
install_ss_panel_mod_UIm
elif [[ $num == "2" ]]
then
NEW_NODE
elif [[ $num == "3" ]]
then
install_node
elif [[ $num == "4" ]]
then
install_BBR
elif [[ $num == "5" ]]
then
install_RS
else 
echo 'input error';
exit 0;
fi;
