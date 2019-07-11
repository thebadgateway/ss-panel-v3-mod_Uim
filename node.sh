#!/bin/bash
#Note the node name here, be sure to fill in the following format:
#Hong Kong Node 1 - 100M Bandwidth
#United States VIP node 1 - 10G bandwidth
#check root
[ $(id -u) != "0" ] && { echo "Error: You must run this script as root"; exit 1; }
rm -rf node*
#General variable settings
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

#IP and config
#IPAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
config="/root/shadowsocks/userapiconfig.py"
get_ip() {
	ip=$(curl -s https://ipinfo.io/ip)
	[[ -z $ip ]] && ip=$(curl -s https://api.ip.sb/ip)
	[[ -z $ip ]] && ip=$(curl -s https://api.ipify.org)
	[[ -z $ip ]] && ip=$(curl -s https://ip.seeip.org)
	[[ -z $ip ]] && ip=$(curl -s https://ifconfig.co/ip)
	[[ -z $ip ]] && ip=$(curl -s https://api.myip.com | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
	[[ -z $ip ]] && ip=$(curl -s icanhazip.com)
	[[ -z $ip ]] && ip=$(curl -s myip.ipip.net | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
	[[ -z $ip ]] && echo -e "\n This chicken is still cut!\n" && exit
}
check_system(){
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
	#res = $(cat /etc/redhat-release | awk '{print $4}')
	#if [[ ${release} == "centos" ]] && [[ ${bit} == "x86_64" ]] && [[ ${res} -ge 7 ]]; then
	if [[ ${release} == "centos" ]] && [[ ${bit} == "x86_64" ]]; then
	echo -e "Your system is[${release} ${bit}],Detection${Green} can ${Font}Build."
	else 
	echo -e "Your system is[${release} ${bit}],Detection${Red} not can ${Font}Build."
	echo -e "${Yellow} Exiting script... ${Font}"
	exit 0;
	fi
}
node_install_start(){
	yum -y groupinstall "Development Tools"
	yum install unzip zip git iptables -y
	yum update nss curl iptables -y
	wget --no-check-certificate https://download.libsodium.org/libsodium/releases/libsodium-1.0.17.tar.gz
	tar xf libsodium-1.0.17.tar.gz && cd libsodium-1.0.17
	./configure && make -j2 && make install
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
	cd /root
	yum -y install python-setuptools
	easy_install pip
	git clone -b manyuser https://github.com/NimaQu/shadowsocks.git "/root/shadowsocks"
	cd shadowsocks
	pip install -r requirements.txt
	pip install cymysql
	cp apiconfig.py userapiconfig.py
	cp config.json user-config.json
}
api(){
    clear
	# Cancel file limit
	sed -i '$a * hard nofile 512000\n* soft nofile 512000' /etc/security/limits.conf
	echo -e "If the following manual configuration error, please manually edit the changes in ${config}"
	read -p "Please enter your docking domain name or IP (for example: http://www.baidu.com defaults to native docking):" WEBAPI_URL
	read -p "Please enter muKey (default marisn in your configuration file):" WEBAPI_TOKEN
	read -p "Please enter the speed measurement cycle (the default is to test the speed every 6 hours):" SPEEDTEST
	read -p "Please enter your node number (Enter default is node ID 3):" NODE_ID
	node_install_start
	cd /root/shadowsocks
	echo -e "modify Config.py...\n"
	get_ip
	WEBAPI_URL=${WEBAPI_URL:-"http://${ip}"}
	sed -i '/WEBAPI_URL/c \WEBAPI_URL = '\'${WEBAPI_URL}\''' ${config}
	#sed -i "s#https://zhaoj.in#${WEBAPI_URL}#" /root/shadowsocks/userapiconfig.py
	WEBAPI_TOKEN=${WEBAPI_TOKEN:-"marisn"}
	sed -i '/WEBAPI_TOKEN/c \WEBAPI_TOKEN = '\'${WEBAPI_TOKEN}\''' ${config}
	#sed -i "s#glzjin#${WEBAPI_TOKEN}#" /root/shadowsocks/userapiconfig.py
	SPEEDTEST=${SPEEDTEST:-"6"}
	sed -i '/SPEED/c \SPEEDTEST = '${SPEEDTEST}'' ${config}
	NODE_ID=${NODE_ID:-"3"}
	sed -i '/NODE_ID/c \NODE_ID = '${NODE_ID}'' ${config}
}
db(){
    clear
	# Cancel file limit
	sed -i '$a * hard nofile 512000\n* soft nofile 512000' /etc/security/limits.conf
	echo -e "If the following manual configuration error, please manually edit the changes in ${config}"
	read -p "Please enter your docking database IP (for example: 127.0.0.1 If you are the machine, please press Enter):" MYSQL_HOST
	read -p "Please enter your database name (default sspanel):" MYSQL_DB
	read -p "Please enter your database port (default 3306):" MYSQL_PORT
	read -p "Please enter your database username (default root):" MYSQL_USER
	read -p "Please enter your database password (default root):" MYSQL_PASS
	read -p "Please enter your node number (Enter default is node ID 3):" NODE_ID
	node_install_start
	cd /root/shadowsocks
	echo -e "modify Config.py...\n"
	get_ip
	sed -i '/API_INTERFACE/c \API_INTERFACE = '\'glzjinmod\''' ${config}
	MYSQL_HOST=${MYSQL_HOST:-"${ip}"}
	sed -i '/MYSQL_HOST/c \MYSQL_HOST = '\'${MYSQL_HOST}\''' ${config}
	MYSQL_DB=${MYSQL_DB:-"sspanel"}
	sed -i '/MYSQL_DB/c \MYSQL_DB = '\'${MYSQL_DB}\''' ${config}
	MYSQL_USER=${MYSQL_USER:-"root"}
	sed -i '/MYSQL_USER/c \MYSQL_USER = '\'${MYSQL_USER}\''' ${config}
	MYSQL_PASS=${MYSQL_PASS:-"root"}
	sed -i '/MYSQL_PASS/c \MYSQL_PASS = '\'${MYSQL_PASS}\''' ${config}
	MYSQL_PORT=${MYSQL_PORT:-"3306"}
	sed -i '/MYSQL_PORT/c \MYSQL_PORT = '${MYSQL_PORT}'' ${config}
	NODE_ID=${NODE_ID:-"3"}
	sed -i '/NODE_ID/c \NODE_ID = '${NODE_ID}'' ${config}
}
clear
check_system
echo -e "\033[1;5;Please select the docking mode:\033[0m"
echo -e "1.API docking mode"
echo -e "2.Database docking mode"
read -t 30 -p "Select:" NODE_MS
case $NODE_MS in
		1)
			api
			;;
		2)
			db
			;;
		*)
		    echo -e "Please select the correct docking mode"
			exit 1
			;;
esac
#Turn off the firewall of CentOS7
systemctl stop firewalld.service
systemctl disable firewalld.service
#iptables
iptables -F
iptables -X  
iptables -I INPUT -p tcp -m tcp --dport 22:65535 -j ACCEPT
iptables -I INPUT -p udp -m udp --dport 22:65535 -j ACCEPT
iptables-save >/etc/sysconfig/iptables
#Remove libsodium
cd /root && rm -rf libsodium*
#Open SS
cd /root/shadowsocks && chmod +x *.sh
./run.sh #后台运行shadowsocks
echo 'iptables-restore /etc/sysconfig/iptables' >> /etc/rc.local
echo 'bash /root/shadowsocks/run.sh' >> /etc/rc.local
chmod +x /etc/rc.d/rc.local && chmod +x /etc/rc.local
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime -r >/dev/null 2>&1
clear
echo -e "${GreenBG} Load the backend simple daemon... please wait... ${Font}"
sleep 2
echo 'if [[ `ps -ef | grep server.py |grep -v grep | wc -l` -ge 1 ]];then
echo "Backend running...";
else
cd /root/shadowsocks;bash run.sh;
fi' > /root/shadowsocks/monitoring.sh
chmod +x /root/shadowsocks/monitoring.sh
yum -y install vixie-cron crontabs
echo '*/5 * * * * /bin/bash /root/shadowsocks/monitoring.sh' >> /var/spool/cron/root
/sbin/service crond restart
if [[ `ps -ef | grep server.py |grep -v grep | wc -l` -ge 1 ]];then
	echo -e "${OK} ${GreenBG} The backend has started ${Font}"
else
	echo -e "${OK} ${RedBG} The backend is not started ${Font}"
	echo -e "Please check if it is a Centos 7.x system, check if the configuration file is correct, check if the code is wrong, please feedback"
	exit 1
fi
