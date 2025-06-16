#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

STRIPE_LINE="----------------------------------------------------"
DOUBLE_STRIPE_LINE="============================================"

HTTP_STR="http"

XP_VERSION="v1.2.1"

API_HOST="https://api.xp.cn"
DL_HOST="https://dl.xp.cn"

current_dir=$(pwd)
INSTALL_LOG_PATH="${current_dir}/xp-install.log"

start_time=`date +%s`

IDC_CODE=""

if [ $(whoami) != "root" ];then
    echo "xp面板安装命令需要root权限执行"
    exit 1;
fi

is64bit=$(getconf LONG_BIT)
if [ "${is64bit}" != '64' ];then
    echo "xp面板仅支持64位系统安装";
fi

arch_check=$(uname -m)
if [ "${arch_check}" != "x86_64" ] && [ "${arch_check}" != "amd64" ]; then
    echo "xp面板仅支持x86_64或者amd64架构CPU的系统安装";
fi

# Centos6不支持安装
centos6_check=$(cat /etc/redhat-release | grep ' 6.' | grep -iE 'centos|Red Hat')
if [ "${centos6_check}" ];then
    echo "xp面板不支持Centos6，请更换Centos7/8或更高版本的系统"
    exit 1
fi

# ubuntu16以下不支持安装
ubuntu_check=$(cat /etc/issue|grep Ubuntu|awk '{print $2}'|cut -f 1 -d '.')
if [ "${ubuntu_check}" ] && [ "${ubuntu_check}" -lt "16" ];then
    echo "xp面板不支持Ubuntu ${ubuntu_check}，请更换Ubuntu18/20或更高版本的系统"
    exit 1
fi

hostname_check=$(cat /etc/hostname)
if [ -z "${hostname_check}" ];then
    echo "无法安装xp面板，因为当前主机名hostname为空，请设置hostname后重新安装"
    exit 1
fi

Get_LocalInfo(){
    if [ -s "/etc/redhat-release" ];then
        SYS_VERSION=$(cat /etc/redhat-release | sed 's/\\n//g' | sed 's/\\l//g')
    elif [ -s "/etc/issue" ]; then
        SYS_VERSION=$(cat /etc/issue | sed 's/\\n//g' | sed 's/\\l//g' | tr -d '\n' | tr -d '\n')
    fi
    SYS_INFO=$(uname -a)
    SYS_BIT=$(getconf LONG_BIT)
    MEM_TOTAL=$(free -m|grep Mem|awk '{print $2}')
    CPU_INFO=$(getconf _NPROCESSORS_ONLN)
    DISK_USE=$(df -h / | tail -n 1 | awk '{printf "size:%s;used:%s;avil:%s;percent:%s", $2, $3, $4, $5}')
}

cd ~
SETUP_PATH="/xp"

Get_Sysinfo(){
    Get_LocalInfo
    
    echo -e ${SYS_VERSION}
    echo -e Bit:${SYS_BIT} Mem:${MEM_TOTAL}M Core:${CPU_INFO}
    echo -e ${SYS_INFO}
    echo -e "${DOUBLE_STRIPE_LINE}"
    echo -e "请截图以上报错信息发给客服人员"
    echo -e "${DOUBLE_STRIPE_LINE}"
    if [ -f "/usr/bin/qrencode" ];then
        echo -e "微信扫码联系企业微信技术求助"
        echo -e "${DOUBLE_STRIPE_LINE}"
        qrencode -t ANSIUTF8 "https://work.weixin.qq.com/kfid/kfc8e99c5e9fb4761c6"
        echo -e "${DOUBLE_STRIPE_LINE}"
    else
        echo -e "手机访问以下链接、扫码联系企业微信技术求助"
        echo -e "${DOUBLE_STRIPE_LINE}"
        echo -e "联系链接:https://work.weixin.qq.com/kfid/kfc8e99c5e9fb4761c6"
        echo -e "${DOUBLE_STRIPE_LINE}"
    fi
}

Red_Err(){
    echo "${DOUBLE_STRIPE_LINE}";
    printf '\033[1;31;40m%b\033[0m\n' "$@";
    Get_Sysinfo
    Analysis_Log
    exit 1;
}

# 检测是否装了别的环境
Env_Check(){
    mysqld_exists=$(ps -ef |grep mysqld|grep -v grep|grep -v /www/server/mysql)
    php_exists=$(ps -ef|grep php-fpm|grep master|grep -v /www/server/php)
    nginx_exists=$(ps -ef|grep nginx|grep master|grep -v /www/server/nginx)
    httpd_exists=$(ps -ef |grep -E 'httpd|apache'|grep -v /www/server/apache|grep -v grep)
    if [ "${php_exists}" ] || [ "${mysqld_exists}" ] || [ "${nginx_exists}" ] || [ "${httpd_exists}" ];then
        Force_Install_Confirm
    fi
}

# 强制安装确认
Force_Install_Confirm(){
    if [ "${INSTALL_FORCE}" ];then
        return
    fi
    echo -e "${STRIPE_LINE}"
    echo -e "检查已有其他Web/mysql环境，继续安装可能影响现有站点及数据"
    echo -e "Web/mysql service is alreday installed,Can't install panel"
    echo -e "${STRIPE_LINE}"
    echo -e "已知风险/Enter yes to force installation"
    read -p "输入yes强制安装: " yes;
    if [ "$yes" != "yes" ];then
        echo -e "------------"
        echo "取消安装"
        exit;
    fi
    start_time=`date +%s`
    INSTALL_FORCE="true"
}

# 获取包管理器
Get_PM(){
    if [ -f "/usr/bin/yum" ] && [ -d "/etc/yum.repos.d" ]; then
        PM="yum"
        elif [ -f "/usr/bin/apt-get" ] && [ -f "/usr/bin/dpkg" ]; then
        PM="apt-get"
    fi
}

# 自动挂载Swap
Auto_Swap_Mem(){
    MEM_TOTAL=$(free -g|grep Mem|awk '{print $2}')
    if [ "${MEM_TOTAL}" -le "1" ];then
        swap=$(free |grep Swap|awk '{print $2}')
        if [ "${swap}" -gt 1 ];then
            echo "Swap total sizse: $swap";
            return;
        fi
        if [ ! -d /www ];then
            mkdir /www
        fi
        swap_file="/www/swap"
        dd if=/dev/zero of=$swap_file bs=1M count=1025
        mkswap -f $swap_file
        swapon $swap_file
        echo "$swap_file    swap    swap    defaults    0 0" >> /etc/fstab
        swap=`free |grep Swap|awk '{print $2}'`
        if [ $swap -gt 1 ];then
            echo "Swap total sizse: $swap";
            return;
        fi
        
        sed -i "/\/www\/swap/d" /etc/fstab
        rm -f $swap_file
    fi    
}

Add_Service(){
    if [ "${PM}" == "yum" ] || [ "${PM}" == "dnf" ]; then
        chkconfig --add xpd
        chkconfig --level 2345 xpd on
        sudo cp ${SETUP_PATH}/init/xpd.service /usr/lib/systemd/system/xpd.service
        sudo chmod +x /usr/lib/systemd/system/xpd.service
        sudo systemctl enable xpd
    elif [ "${PM}" == "apt-get" ]; then
        sudo update-rc.d xpd defaults
    fi
}

# 设置软件源
Set_Centos_Repo(){
    huawei_check=$(cat /etc/motd |grep "Huawei Cloud")
    if [ "${huawei_check}" ] && [ "${is64bit}" == "64" ];then
        \cp -rpa /etc/yum.repos.d/ /etc/yumBak
        sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo
        sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.epel.cloud|g' /etc/yum.repos.d/CentOS-*.repo
        rm -f /etc/yum.repos.d/epel.repo
        rm -f /etc/yum.repos.d/epel-*
    fi
    aliyun_check=$(cat /etc/motd|grep "Alibaba Cloud ")
    if [  "${aliyun_check}" ] && [ "${is64bit}" == "64" ] && [ ! -f "/etc/yum.repos.d/Centos-vault-8.5.2111.repo" ];then
        rename '.repo' '.repo.bak' /etc/yum.repos.d/*.repo
        wget https://mirrors.aliyun.com/repo/Centos-vault-8.5.2111.repo -O /etc/yum.repos.d/Centos-vault-8.5.2111.repo
        wget https://mirrors.aliyun.com/repo/epel-archive-8.repo -O /etc/yum.repos.d/epel-archive-8.repo
        sed -i 's/mirrors.cloud.aliyuncs.com/url_tmp/g'  /etc/yum.repos.d/Centos-vault-8.5.2111.repo &&  sed -i 's/mirrors.aliyun.com/mirrors.cloud.aliyuncs.com/g' /etc/yum.repos.d/Centos-vault-8.5.2111.repo && sed -i 's/url_tmp/mirrors.aliyun.com/g' /etc/yum.repos.d/Centos-vault-8.5.2111.repo
        sed -i 's/mirrors.aliyun.com/mirrors.cloud.aliyuncs.com/g' /etc/yum.repos.d/epel-archive-8.repo
    fi
    mirror_check=$(cat /etc/yum.repos.d/CentOS-Linux-AppStream.repo |grep "[^#]mirror.centos.org")
    if [ "${mirror_check}" ] && [ "${is64bit}" == "64" ];then
        \cp -rpa /etc/yum.repos.d/ /etc/yumBak
        sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo
        sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.epel.cloud|g' /etc/yum.repos.d/CentOS-*.repo
    fi
}

# 安装rpm的基础包
Install_RPM_Base_Pkg(){
    yum_path=/etc/yum.conf
    centos8_check=$(cat /etc/redhat-release | grep ' 8.' | grep -iE 'centos|Red Hat')
    if [ "${centos8_check}" ];then
        Set_Centos_Repo
    fi
    is_exc=$(cat $yum_path|grep httpd)
    if [ "$is_exc" = "" ];then
        echo "exclude=httpd nginx php mysql mairadb python-psutil python2-psutil" >> $yum_path
    fi
    
    if [ -f "/etc/redhat-release" ] && [ $(cat /etc/os-release|grep PLATFORM_ID|grep -oE "el8") ];then
        yum config-manager --set-enabled powertools
        yum config-manager --set-enabled PowerTools
    fi
    
    if [ -f "/etc/redhat-release" ] && [ $(cat /etc/os-release|grep PLATFORM_ID|grep -oE "el9") ];then
        dnf config-manager --set-enabled crb -y
    fi
    
    # 同步服务器时间
    echo 'Synchronizing system time...'
    get_server_time=$(curl -sS --connect-timeout 3 -m 60 ${API_HOST}/api/getTime)
    if [ "${get_server_time}" ];then
        date -s "$(date -d @$get_server_time +"%Y-%m-%d %H:%M:%S")"
    fi
    
    if [ -z "${centos8_check}" ]; then
        yum install ntp -y
        rm -rf /etc/localtime
        ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
        
        # 尝试同步国际时间(从ntp服务器)
        ntpdate 0.asia.pool.ntp.org
        setenforce 0
    fi
        
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
    yum_packs="libcurl-devel wget tar gcc make zip unzip openssl openssl-devel libxml2 libxml2-devel libxslt* zlib zlib-devel libjpeg-devel libpng-devel libwebp libwebp-devel freetype freetype-devel lsof pcre pcre-devel vixie-cron crontabs icu libicu-devel c-ares libffi-devel bzip2-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel qrencode clang libaio ncurses-compat-libs"
    echo "下列软件将被安装：${yum_packs}"
    yum install -y --skip-broken ${yum_packs}
    
    for yum_pack in ${yum_packs}
    do
        rpm_pack=$(rpm -q ${yum_pack})
        pack_check=$(echo ${rpm_pack}|grep not)
        if [ "${pack_check}" ]; then
            yum install ${yum_pack} -y
        fi
    done

    echo "安装必备软件：iptables"
    yum install -y iptables

    if [ -f "/usr/bin/dnf" ]; then
        dnf install -y redhat-rpm-config
    fi
    
    ali_os=$(cat /etc/redhat-release |grep "Alibaba Cloud Linux release 3")
    if [ -z "${ali_os}" ];then
        yum install epel-release -y
    fi
}

# 安装deb基础包
Install_Deb_Base_Pkg(){
    # 如果apt存在锁，则手动删除释放锁文件
    lf_pid=$(sudo lsof /var/lib/dpkg/lock-frontend | awk 'NR==2{print $2}')
    if [ -n "$lf_pid" ]; then
        sudo kill -9 $lf_pid
    fi
    l_pid=$(sudo lsof /var/lib/dpkg/lock | awk 'NR==2{print $2}')
    if [ -n "$l_pid" ]; then
        sudo kill -9 $l_pid
    fi
    
    ln -sf bash /bin/sh
    ubuntu_22=$(cat /etc/issue|grep "Ubuntu 22")
    if [ "${ubuntu_22}" ];then
        apt-get remove needrestart -y
    fi
    aliyun_check=$(cat /etc/motd|grep "Alibaba Cloud ")
    if [ "${aliyun_check}" ] && [ "${ubuntu_22}" ];then
        apt-get remove libicu70 -y
    fi
    apt-get update -y
    apt-get install bash -y
    if [ -f "/usr/bin/bash" ];then
        ln -sf /usr/bin/bash /bin/sh
    fi
    apt-get install ruby -y
    apt-get install lsb-release -y

    libcurl_ver=$(dpkg -l|grep libcurl4|awk '{print $3}')
    if [ "${libcurl_ver}" == "7.68.0-1ubuntu2.8" ];then
        apt-get remove libcurl4 -y
        apt-get install curl -y
    fi

    deb_packs="wget curl libcurl4-openssl-dev gcc make zip unzip tar openssl libssl-dev libxml2 libxml2-dev zlib1g zlib1g-dev libjpeg-dev libpng-dev lsof libpcre3 libpcre3-dev cron net-tools swig build-essential libffi-dev libbz2-dev libncurses-dev libsqlite3-dev iptables libreadline-dev tk-dev libgdbm-dev libdb-dev libdb++-dev libpcap-dev xz-utils git qrencode libwebp-dev libsodium-dev clang libaio1 libncurses5"
    echo "下列软件将被安装：${deb_packs}"
    apt-get install -y -m $deb_packs --force-yes

    for deb_pack in ${deb_packs}
    do
        pack_check=$(dpkg -l|grep ${deb_pack})
        if [ "$?" -ne "0" ] ;then
            apt-get install -y $deb_pack
        fi
    done

    echo "安装必备软件：iptables"
    apt-get install -y iptables

    if [ ! -d '/etc/letsencrypt' ];then
        mkdir -p /etc/letsencryp
        mkdir -p /var/spool/cron
        if [ ! -f '/var/spool/cron/crontabs/root' ];then
            echo '' > /var/spool/cron/crontabs/root
            chmod 600 /var/spool/cron/crontabs/root
        fi
    fi
}

Init_DB(){
    if [ ! -d "${SETUP_PATH}/db" ];then
        Red_Err "数据库文件缺失，请检查安装包"
        exit 1
    fi
    if [ ! -f "${SETUP_PATH}/init/init.sql" ];then
        Red_Err "初始化数据文件缺失，请检查安装包"
        exit 1
    fi
    
    chmod -R 0777 ${SETUP_PATH}/db

    time_now_str=$(date "+%Y-%m-%d %H:%M:%S")
    sed -i -e "s/{port}/${panel_port}/g" -e "s/{account}/${panel_user}/g" -e "s/{pwd}/${panel_pwd}/g" -e "s/{pwdMd5}/${panel_pwd_md5}/g" -e "s/{safeEntry}/${safe_entry}/g" -e "s/{time}/${time_now_str}/g" -e "s/{xpVersion}/${XP_VERSION}/g" -e "s/{idcCode}/${IDC_CODE}/g" ${SETUP_PATH}/init/init.sql

    msg=$(sqlite3 ${SETUP_PATH}/db/app.db < ${SETUP_PATH}/init/init.sql 2>&1)
    if [ $? -ne 0 ];then
        Red_Err "数据库初始化失败，错误信息：${msg}"
        exit 1
    fi
}

Down_Deps(){
    for pkg in $@
    do
        dl_url="${DL_HOST}/deps/${pkg}.tar.gz"
        cd ${SETUP_PATH}/download
        wget -O ./${pkg}.tar.gz "${dl_url}"
        mkdir -p ./${pkg}
        tar -zxvf ./${pkg}.tar.gz -C ./${pkg}
        sudo bash ./${pkg}/${pkg}_install.sh
        cd $current_dir
    done
}

Check_CMD(){
    for cmd in $@
    do
        if ! command -v "$cmd" &> /dev/null; then
            Red_Err "Error: Command '$cmd' not found."
            exit 1
        fi
    done
}

Down_XP(){
    mkdir -p $SETUP_PATH/download
    wget -O ${SETUP_PATH}/download/xp-panel.tar.gz "${DL_HOST}/dl/xp/xp-panel.tar.gz"
}

Init_Tools(){
    xp_tools_dir="/xp/tools"
 
    if [ -d "$xp_tools_dir" ]; then
        for tool in "$xp_tools_dir"/*.sh; do
            filename=$(basename "$tool" .sh)
            if [ -L "/usr/bin/$filename" ]; then
                rm "/usr/bin/$filename"
            fi
            ln -s "$tool" "/usr/bin/$filename"
        done
    fi
}

Init_XP(){
    Check_CMD sqlite3 iptables vsftpd

    mkdir -p $SETUP_PATH/server
    mkdir -p $SETUP_PATH/panel
    mkdir -p $SETUP_PATH/wwwlogs
    mkdir -p $SETUP_PATH/applogs
    mkdir -p $SETUP_PATH/www
    mkdir -p $SETUP_PATH/backup
    mkdir -p $SETUP_PATH/db
    mkdir -p $SETUP_PATH/init

    cd $SETUP_PATH
    sudo tar -zxvf $SETUP_PATH/download/xp-panel.tar.gz -C $SETUP_PATH > /dev/null 2>&1

    sudo chown -R root /xp/*
    sudo chmod -R 0777 /xp/*

    # 给程序执行权限
    sudo chmod +x /xp/panel/app
    sudo chmod +x /xp/tasks/xp-tasks
    sudo chmod +x /xp/*.sh
    
    if [ ! -d "/etc/init.d" ];then
        mkdir -p /etc/init.d
    fi
    
    if [ -f "/etc/init.d/xpd" ]; then
        /etc/init.d/xpd stop
        sleep 1
    fi 

    # 添加一个www用户
    run_user="www"
    www_user=$(cat /etc/passwd|cut -d ":" -f 1|grep ^www$)
    if [ "${www_user}" != "www" ];then
        groupadd ${run_user}
        useradd -s /sbin/nologin -g ${run_user} ${run_user}
    fi
    
    # 设置面板端口
    panel_port=""
    if [ "${PANEL_PORT}" ];then 
        # 检查端口是否被占用
        result=$(netstat -tln | grep ":${PANEL_PORT}")
        if [ -n "$result" ]; then
            Red_Err "安装面板失败，指定的端口 ${PANEL_PORT} 已被占用"
        fi
        panel_port=$PANEL_PORT
    else
        # 随机生成端口号
        panel_port=$(expr $RANDOM % 55535 + 10000)
        # 检查端口是否被占用
        result=$(netstat -tln | grep ":$panel_port")
        while [ -n "$result" ]; do
            panel_port=$(expr $RANDOM % 55535 + 10000)
            result=$(netstat -tln | grep ":$panel_port")
        done
    fi

    # 设置面板用户名
    panel_user=$(cat /dev/urandom | head -n 16 | md5sum | head -c 8)
    if [ "$PANEL_USER" ];then
        panel_user=$PANEL_USER
    fi

    # 生成面板默认密码
    panel_pwd=$(cat /dev/urandom | head -n 16 | md5sum | head -c 8)
    if [ "$PANEL_PWD" ];then
        panel_pwd=$PANEL_PWD
    fi
    sleep 1
    panel_pwd_md5=$(echo -n $panel_pwd | md5sum | cut -d ' ' -f 1)

    # 生成安全入口
    if [ -z "$SAFE_ENTRY" ];then
        safe_entry=$(cat /dev/urandom | head -n 16 | md5sum | head -c 6)
    else
        safe_entry=$SAFE_ENTRY
    fi
    
    # 安装xp服务
    sudo cp ${SETUP_PATH}/init/xpd /etc/init.d/xpd
    sudo chmod +x /etc/init.d/xpd

    # 给xp脚本创建软连接
    sudo chmod 777 /xp/xp.sh
    if [ -f "/usr/bin/xp" ];then
        sudo rm -f /usr/bin/xp
    fi
    sudo ln -s /xp/xp.sh /usr/bin/xp
    
    # 给tools目录下的脚本创建软连接
    Init_Tools
    
    Init_DB

    # 配置vsftpd
    sudo touch /var/log/vsftpd.log
    sudo chmod 777 /var/log/vsftpd.log
    sudo touch /var/log/vsftpd_xfer.log
    sudo chmod 777 /var/log/vsftpd_xfer.log
    sudo setsid /usr/local/bin/vsftpd /etc/vsftpd.conf &
}

Get_IP_Info(){
	IP_ADDR=""
	IP_ADDR=$(curl -sS --connect-timeout 10 -m 60 ${API_HOST}/api/myIP)

	LOCAL_IP=$(ip addr | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -E -v "^127\.|^255\.|^0\." | head -n 1)
}

Kill_Old_XP(){
    sudo pkill -f /xp/panel/app
    sudo pkill -f /xp/tasks/xp-task
}

End(){
    sudo bash $SETUP_PATH/run.sh
    echo -e "\033[32m小皮面板启动中\033[0m"

    Panel_Pid=$(ps -ef | grep /xp/panel/app | grep -v grep | awk '{print $2}')
    Panel_Status="面板状态：未知"
    if [ -n "${Panel_Pid}" ]; then
        Panel_Status="\033[32m面板状态：运行中\033[0m"
    else
        Panel_Status="\033[31m面板状态：未运行\033[0m"
    fi

    Task_Pid=$(sudo ps -ef | grep /xp/tasks/xp-tasks | grep -v grep | awk '{print $2}')
    Task_Status="面板状态：未知"
    if [ -n "${Task_Pid}" ]; then
        Task_Status="\033[32m队列状态：运行中\033[0m"
    else
        Task_Status="\033[31m队列状态：未运行\033[0m"
    fi
    echo -e "================================================================"
    echo -e " \033[32m小皮面板安装成功\033[0m"
    echo -e "=========================面板状态==============================="
    echo -e " ${Panel_Status}"
    echo -e " ${Task_Status}"
    echo -e "=========================面板账户信息==========================="
    echo -e ""
    echo -e " 面板版本: ${XP_VERSION}"
    echo -e " 外网面板地址: ${HTTP_STR}://${IP_ADDR}:${panel_port}/${safe_entry}"
    echo -e " 内网面板地址: ${HTTP_STR}://${LOCAL_IP}:${panel_port}/${safe_entry}"
    echo -e " username: ${panel_user}"
    echo -e " password: ${panel_pwd}"
    echo -e ""
    echo -e "=========================面板注意事项==========================="
    echo -e ""
    echo -e " 【云服务器】请在安全组放行 $panel_port 端口"
    echo -e " 面板工具命令： xp"
    echo -e ""
    echo -e "================================================================"
    end_time=`date +%s`
    ((out_time=($end_time-$start_time)))
    echo -e "安装花费时间:\033[32m $out_time \033[0m秒"
    echo -e "安装日志路径:\033[32m $INSTALL_LOG_PATH \033[0m"
}

Install_Tip(){
    echo "+${STRIPE_LINE}${STRIPE_LINE}"
    echo "| xp-panel for CentOS/Ubuntu/Debian"
    echo "+${STRIPE_LINE}${STRIPE_LINE}"
    echo "| Copyright © 2015-2050 XP-SOFT(https://xp.cn) All rights reserved."
    echo "+${STRIPE_LINE}${STRIPE_LINE}"
    echo "| The WebPanel URL will be http://SERVER_IP:${PANEL_PORT} when installed."
    echo "+${STRIPE_LINE}${STRIPE_LINE}"
    echo "| 为了您的正常使用，请确保使用全新或纯净的系统安装小皮面板"
    echo "+${STRIPE_LINE}${STRIPE_LINE}"
    echo "| 安装后可能会影响您系统原有的防火墙、ftp、数据库、开发环境等"
    echo "+${STRIPE_LINE}${STRIPE_LINE}"
    echo "| 开始安装后将会停止系统正在运行的小皮面板，并覆盖之前面板的数据，请注意备份"
    echo "+${STRIPE_LINE}${STRIPE_LINE}"
}

Open_Log(){
    touch $INSTALL_LOG_PATH
    exec 4>$INSTALL_LOG_PATH
    exec > >(tee >(cat >&4)) 2>&1
}

Analysis_Log(){
    exec 4>&-
    err_end=$(grep -n "请截图以上报错信息发给客服人员" $INSTALL_LOG_PATH | cut -d: -f1 | tail -n 1)
    if [ -n "$err_end" ]; then
        err_start=$(($err_end - 50))
        if [ $err_start -lt 0 ]; then
            err_start=1
        fi
        err=$(sed 's/\x1B\[[0-9;]*[JKmsu]//g' $INSTALL_LOG_PATH | sed -n "${err_start},${err_end}p" | tr '\n' ';')
        d='{"ver": "'${XP_VERSION}'", "err": "'${err}'","sysInfo": "'${SYS_INFO}'", "ip":"", "idc":"'${IDC_CODE}'"}'
        curl -s -X POST -H "Content-Type: application/json" -d "${d}" "${API_HOST}/api/installErr" 2>&1 >/dev/null
    fi
    
    err_end=$(grep -n "状态：未运行" $INSTALL_LOG_PATH | cut -d: -f1 | tail -n 1)
    if [ -n "$err_end" ]; then
        err_start=$(($err_end - 50))
        if [ $err_start -lt 0 ]; then
            err_start=1
        fi
        err=$(sed 's/\x1B\[[0-9;]*[JKmsu]//g' $INSTALL_LOG_PATH | sed -n "${err_start},${err_end}p" | tr '\n' ';')
        d='{"ver": "'${XP_VERSION}'", "err": "'${err}'","sysInfo": "'${SYS_INFO}'"}'
        curl -s -X POST -H "Content-Type: application/json" -d "${d}" "${API_HOST}/api/installErr" 2>&1 >/dev/null
    fi
}

Disable_Sudo_TTY(){
    if [ -f "/etc/sudoers" ]; then
        tty_mode=$(grep '^Default.*requiretty' /etc/sudoers)
        if [ -n "$tty_mode" ]; then
            sed -i 's/^Default.*requiretty/#&/' /etc/sudoers
        fi
    fi
}

Select_DlNode(){
    echo "select download node..."
    json_str=$(curl -s "${API_HOST}/api/dlNodes")
    if ! echo $json_str | grep -q '"ip":'; then
        echo "get download nodes failed, use default node"
        return
    fi
    ips=$(echo $json_str | grep -oP '"ip"\s*:\s*"\K[^"]+')
    min_delay_sec=5.0
    fasted_ip=""
    for ip in $ips
    do
        delay_sec=$(timeout 5 curl -o /dev/null -s -w "%{time_total}" ${ip} || echo 999.0)
        comp_result=$(echo "${delay_sec} < ${min_delay_sec}" | awk '{print ($1 < $3) ? "1" : "0"}')
        if [ $comp_result -eq 1 ]; then
            min_delay_sec=$delay_sec
            fasted_ip=$ip
        fi
    done
    if [ -z "$fasted_ip" ]; then
        echo "test download nodes error, use default node"
        return
    fi

    if grep -q "dl.xp.cn" /etc/hosts; then
        sed -i "s/.*dl.xp.cn.*/${fasted_ip} dl.xp.cn/g" /etc/hosts
    else
        echo -e "\n${fasted_ip} dl.xp.cn\n" >> /etc/hosts
    fi
    echo "select fasted download node finish"
}

Set_Cent_Repo_Source() {
    distro=$(cat /etc/centos-release | awk '{print $1}')
    version=$(cat /etc/centos-release | awk '{print $4}' | cut -d '.' -f1)
    if [ "$distro" == "CentOS" ]; then
        echo "开始替换 CentOS 的源为阿里源..."
        if [ "$version" == "7" ]; then
            echo "正在替换为 CentOS 7 的阿里源..."
            sudo mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
            sudo curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
            sudo yum clean all && sudo yum makecache
            echo "替换完成！"
        elif [ "$version" == "8" ]; then
            echo "正在替换为 CentOS 8 的阿里源..."
            sudo mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
            sudo curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
            sudo yum clean all && sudo yum makecache
            echo "替换完成！"
        else
            echo "不支持替换阿里源的 CentOS 版本：$version"
        fi
    fi
}

Install_Main(){
    Kill_Old_XP
    Env_Check
    Get_PM
    
    Auto_Swap_Mem

    Set_Cent_Repo_Source
    
    if [ "${PM}" = "yum" ]; then
        Install_RPM_Base_Pkg
        elif [ "${PM}" = "apt-get" ]; then
        Install_Deb_Base_Pkg
    fi

    Get_IP_Info

    Select_DlNode
    
    Down_XP
    Down_Deps sqlite3 vsftpd

    Open_Log

    Disable_Sudo_TTY
    
    Init_XP
    Add_Service
    End
    
    Analysis_Log
}

Install_Tip

go="wait" # 确认安装的等待
while [ ${#} -gt 0 ]; do
    case $1 in
        -u|--user)
            PANEL_USER=$2
            shift 1
        ;;
        -p|--password)
            PANEL_PWD=$2
            shift 1
        ;;
        -P|--port)
            PANEL_PORT=$2
            shift 1
        ;;
        --safe-entry)
            SAFE_ENTRY=$2
            shift 1
        ;;
        --ssl-disable)
            SSL_PL="disable"
        ;;
        -y)
            go="y"
        ;;
        *)
            IDC_CODE=$1
        ;;
    esac
    shift 1
done

while [ "$go" != 'Y' ] && [ "$go" != 'y' ] && [ "$go" != 'n' ] && [ "$go" != '' ]
do
    read -p "Do you want to install xp-panel to the $SETUP_PATH directory now?(Y/n): " go;
done

if [ "$go" == 'n' ];then
    exit;
fi

Get_LocalInfo

d='{"hostname": "'${hostname_check}'", "cpu": "'${CPU_INFO}'", "memory": "'${MEM_TOTAL}'", "diskUsage": "'${DISK_USE}'", "sysInfo": "'${SYS_INFO}'", "os": "'${SYS_VERSION}'", "idc": "'${IDC_CODE}'"}'
curl -s -X POST -H "Content-Type: application/json" -d "${d}" "${API_HOST}/api/addInstallInfo" 2>&1 >/dev/null

Install_Main

# 安装完成删除安装包
rm -f $SETUP_PATH/download/xp-panel.tar.gz