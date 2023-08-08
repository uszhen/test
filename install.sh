#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
webPort=19090
version=v1.0
downLoadUrl=https://github.com/uszhen/test/releases/download/
serverSoft=linux_amd64_server
clientSoft=linux_amd64_client
serverUrl=${downLoadUrl}${version}/${serverSoft}.tar.gz
clientUrl=${downLoadUrl}${version}/${clientSoft}.tar.gz
s5Path=/opt/nps-socks5/
ipAdd=Detection failed

if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" -o -e /etc/redhat-release ];then
    OS=CentOS
    [ -n "$(grep ' 7\.' /etc/redhat-release)" ] && CentOS_RHEL_version=7
    [ -n "$(grep ' 6\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release6 15' /etc/issue)" ] && CentOS_RHEL_version=6
    [ -n "$(grep ' 5\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release5' /etc/issue)" ] && CentOS_RHEL_version=5
elif [ -n "$(grep 'Amazon Linux AMI release' /etc/issue)" -o -e /etc/system-release ];then
    OS=CentOS
    CentOS_RHEL_version=6
elif [ -n "$(grep bian /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Debian' ];then
    OS=Debian
    [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
    Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Deepin /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Deepin' ];then
    OS=Debian
    [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
    Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Ubuntu /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Ubuntu' -o -n "$(grep 'Linux Mint' /etc/issue)" ];then
    OS=Ubuntu
    [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
    Ubuntu_version=$(lsb_release -sr | awk -F. '{print $1}')
    [ -n "$(grep 'Linux Mint 18' /etc/issue)" ] && Ubuntu_version=16
else
    echo "Does not support this OS, Please contact the author! "
    kill -9 $$
fi

#Install Basic Tools
init(){
if [[ ${OS} == Ubuntu ]];then
	apt-get  install git unzip wget -y
	apt-get  install curl
fi
if [[ ${OS} == CentOS ]];then
	yum install git unzip wget -y
  yum -y install curl
fi
if [[ ${OS} == Debian ]];then
	apt-get install git unzip wget -y
	apt-get install curl
fi
}

unstallServer(){
	if [[ -d ${s5Path}${serverSoft} ]];then
      cd ${s5Path}${serverSoft} && nps stop && nps uninstall
      rm -rf /etc/nps
      rm -rf /usr/bin/nps
      rm -rf ${s5Path}${serverSoft}
	fi
	 echo "Uninstalled server successfully"
}

unstallClient(){
  if [[ -d ${s5Path}${clientSoft} ]];then
  	  cd ${s5Path}${clientSoft} && npc stop &&  ./npc uninstall
    	rm -rf ${s5Path}${clientSoft}
    	rm -rf ${s5Path}${clientSoft}.tar.gz
  fi
  echo "Uninstalled client successfully"
}

allUninstall(){
  unstallServer
  unstallClient
  #Delete the previous
  if [[ -d ${s5Path} ]];then
	  rm -rf ${s5Path}
	fi
}

checkIp(){

ipAdd=`curl http://ifconfig.info -s --connect-timeout 10`
clear
echo "current ip address："${ipAdd}
read -p "If this is not correct please stop the installation or enter the server manually ip：(y/n/ip)： " choice
	
	if [[ "$choice" == 'n' || "$choice" == 'N' ]]; then
			echo "End of installation"
			exit 0
	elif [[ "${choice}" == '' && "${ipAdd}" == 'detection failure' ]]; then
			echo "Installation failed: incorrect ip"
			exit 0
	
	elif [[ "$choice" != 'y' && "$choice" != 'Y' && "${choice}" != '' ]]; then
		check_ip "${choice}"
	fi
}

#2.Download Server
DownloadServer()
{
echo "Please be patient while downloading the nps-socks5 service..."
if [[ ! -d ${s5Path} ]];then
	mkdir -p ${s5Path}	
fi

#Server
wget -P ${s5Path} --no-cookie --no-check-certificate ${serverUrl} 2>&1 | progressfilt


if [[ ! -f ${s5Path}${serverSoft}.tar.gz ]]; then
	echo "Server file download failure"${errorMsg}
	exit 0
fi

}

DownloadClient()
{
echo "Please be patient while downloading the nps-socks5 client..."
if [[ ! -d ${s5Path} ]];then
	mkdir -p ${s5Path}	
fi


#client
wget -P ${s5Path} --no-cookie --no-check-certificate ${clientUrl} 2>&1 | progressfilt


if [[ ! -f ${s5Path}${clientSoft}.tar.gz ]]; then
	echo "客户端文件下载失败"${errorMsg}
	exit 0
fi
}

#3.Client file download failed
InstallServer()
{
echo ""
echo "The server files are being unpacked..."

tar zxvf ${s5Path}${serverSoft}.tar.gz -C ${s5Path}

cd ${s5Path}${serverSoft}
sudo  ./nps install && nps start
}

InstallClient()
{

echo ""
echo "Client file decompression in progress..."
if [[ ! -d ${s5Path}${clientSoft} ]]; then
echo "-------------"${s5Path}${clientSoft}
mkdir -p ${s5Path}${clientSoft}
fi
tar zxvf ${s5Path}${clientSoft}.tar.gz -C ${s5Path}${clientSoft}

clear
echo "Client file installation in progress..."
cd ${s5Path}${clientSoft}
if [[ $menuChoice == 1 ]];then
./npc install  -server=${ipAdd}:8025 -vkey=ij7poeu2d9btjbd3 -type=tcp && npc start
else
echo "The server parameters are in the [Server]->Services list + sign"
echo "analog：./npc -server=xxx.xxx.xxx.172:8089 -vkey=test8socks8world2023 -type=tcp"
echo "Just type:-server=xxx.xxx.xxx.172:8089 -vkey=test8socks8world2023 -type=tcp 即可"
read -p "Please enter server-side parameters： " serverParam
./npc install ${serverParam} && npc start
fi
}



checkServer(){
#Check if the server is installed successfully
SPID=`ps -ef|grep nps |grep -v grep|awk '{print $2}'`
if [[ -z ${SPID} ]]; then
echo ${SPID}"SPID----------------------"
echo "Server installation failed"${errorMsg}
unstallServer
exit 0
fi
}


checkClient(){

CPID=`ps -ef|grep npc |grep -v grep|awk '{print $2}'`
if [[ -z ${CPID} ]]; then
echo "Client installation failed"${errorMsg}
unstallClient
exit 0
fi
}



function check_ip(){
        IP=$1
        VALID_CHECK=$(echo $IP|awk -F. '$1<=255 && $2<=255 && $3<=255 && $4<=255 {print "yes"}')
        
        if echo $IP|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$">/dev/null; then
                if [[ $VALID_CHECK == "yes" ]]; then
                        return=$IP
                else
                        echo "Installation failed: incorrect ip"
						exit 0
                fi
        else
               echo "Installation failed: non-ip"
			   exit 0
        fi
}

progressfilt ()
{
    local flag=false c count cr=$'\r' nl=$'\n'
    while IFS='' read -d '' -rn 1 c
    do
        if $flag
        then
            printf '%s' "$c"
        else
            if [[ $c != $cr && $c != $nl ]]
            then
                count=0
            else
                ((count++))
                if ((count > 1))
                then
                    flag=true
                fi
            fi
        fi
    done
}


menu(){
echo '1.Full installation (recommended if there is only "one" server)'
echo '2.Installation of the server (recommended to be installed on a "domestic" server [transit])'
echo '3.Installation of the client (recommended to be installed on a "foreign" server)'
echo "4.Uninstalling the server"
echo "5.Uninstalling the client"
echo "6.full uninstallation"
echo "0.quit"
while :; do echo
	read -p "please select： " menuChoice
	if [[ ! $menuChoice =~ ^[0-6]$ ]]; then
		echo "Input error! Please enter the correct number!"
	else
		break	
	fi
done


if [[ $menuChoice == 0 ]];then
	exit 0
fi	

if [[ $menuChoice == 1 ]];then
	#Installation of the server
	init
	checkIp
	
	allUninstall
	DownloadServer
	DownloadClient
	InstallServer
	InstallClient
	checkServer
	checkClient
	clear
	echo "--Installation Successful ------"${errorMsg}
	echo "--Backstage management address"${ipAdd}":"${webPort}
	echo "--Login account admin"
	echo "--login password password"
	echo "Default socks5 account information:username admin password password port 6666"
	echo "If you need to modify the background management port and account password please see github"

fi
if [[ $menuChoice == 2 ]];then
	init
	checkIp
	unstallServer
	DownloadServer
	InstallServer
	checkServer
	clear
	echo "--Installation Successful ------"${errorMsg}
	echo "--Background management address"${ipAdd}":"${webPort}
	echo "--Login account admin"
	echo "--login password password"
fi

if [[ $menuChoice == 3 ]];then
	clear
	unstallClient
	DownloadClient
	clear
	InstallClient
	checkClient
	echo "--Successful installation------"${errorMsg}
fi
if [[ $menuChoice == 4 ]];then
unstallServer
fi

if [[ $menuChoice == 5 ]];then
unstallClient
fi

if [[ $menuChoice == 6 ]];then
allUninstall
fi
}
menu

