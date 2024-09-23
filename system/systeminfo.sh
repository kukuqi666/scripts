#!/bin/bash

echo "-------------------------------System Information----------------------------"
echo -e "Hostname:\t\t"`hostname`
echo -e "Uptime:\t\t\t"`uptime | awk '{print $3,$4}' | sed 's/,//'`
echo -e "Manufacturer:\t\t"`cat /sys/class/dmi/id/chassis_vendor 2>/dev/null || echo "Unknown"`
echo -e "Product Name:\t\t"`cat /sys/class/dmi/id/product_name 2>/dev/null || echo "Unknown"`
echo -e "Version:\t\t"`cat /sys/class/dmi/id/product_version 2>/dev/null || echo "Unknown"`
echo -e "Serial Number:\t\t"`cat /sys/class/dmi/id/product_serial 2>/dev/null || echo "Unknown"`
vserver=$(lscpu | grep Hypervisor | wc -l)
if [ $vserver -gt 0 ]; then
    echo -e "Machine Type:\t\tVM"
else
    echo -e "Machine Type:\t\tPhysical"
fi
echo -e "Operating System:\t"`hostnamectl | grep "Operating System" | cut -d ' ' -f5-`
echo -e "Kernel:\t\t\t"`uname -r`
echo -e "Architecture:\t\t"`arch`
echo -e "Processor Name:\t\t"`awk -F':' '/^model name/ {print $2}' /proc/cpuinfo | uniq | sed -e 's/^[ \t]*//'`
echo -e "Active User:\t\t"`w | cut -d ' ' -f1 | grep -v USER | xargs -n1`
echo -e "System Main IP:\t\t"`hostname -I`
echo ""

echo "-------------------------------CPU/Memory Usage------------------------------"
echo -e "Memory Usage:\t"`free | awk '/Mem/{printf("%.2f%%"), $3/$2*100}'`
echo -e "Swap Usage:\t"`free | awk '/Swap/{printf("%.2f%%"), $3/$2*100}'`
echo -e "CPU Usage:\t"`cat /proc/stat | awk '/cpu/{printf("%.2f%%\n"), ($2+$4)*100/($2+$4+$5)}' | awk '{print $0}' | head -1`
echo ""

echo "-------------------------------Disk Usage >80%-------------------------------"
df -Ph | sed s/%//g | awk '{ if($5 > 80) print $0;}'
echo ""

echo "-------------------------------For WWN Details-------------------------------"
vserver=$(lscpu | grep Hypervisor | wc -l)
if [ $vserver -gt 0 ]; then
    echo "$(hostname) is a VM"
else
    if [ -d /sys/class/fc_host ]; then
        cat /sys/class/fc_host/host*/port_name 2>/dev/null || echo "WWN not available"
    else
        echo "WWN not available"
    fi
fi
echo ""

echo "-------------------------------Oracle DB Instances---------------------------"
if id oracle >/dev/null 2>&1; then
    oracle_ps=$(/bin/ps -ef | grep pmon | grep -v grep)
    if [ -n "$oracle_ps" ]; then
        echo "Oracle DB instances running:"
        echo "$oracle_ps"
    else
        echo "No Oracle DB instances found"
    fi
else
    echo "Oracle user does not exist on $(hostname)"
fi
echo ""

if (( $(cat /etc/*-release | grep -w "Oracle|Red Hat|CentOS|Fedora" | wc -l) > 0 )); then
    echo "-------------------------------Package Updates-------------------------------"
    yum updateinfo summary | grep 'Security|Bugfix|Enhancement' || echo "No updates available"
    echo "-----------------------------------------------------------------------------"
else
    echo "-------------------------------Package Updates-------------------------------"
    if [ -f /var/lib/update-notifier/updates-available ]; then
        cat /var/lib/update-notifier/updates-available || echo "No updates available"
    else
        echo "Update notifier not available"
    fi
    echo "-----------------------------------------------------------------------------"
fi

# 以下是集成的第二部分脚本
echo "-------------------------------Kernel version------------------------------"
cat /proc/version
echo ""  # 添加一个空行

# 检查是否存在 Red Hat 版本的文件
if [ -f /etc/redhat-release ]; then
    echo "Red Hat version:"
    cat /etc/redhat-release
else
    echo "No Red Hat version file found."
fi
echo ""  # 添加一个空行

# 输出系统详细信息
echo "System details:"
uname -a
echo ""  # 添加一个空行

# 输出操作系统信息
if [ -f /etc/os-release ]; then
    echo "OS Release:"
    cat /etc/os-release
else
    echo "No OS release file found."
fi
echo ""  # 添加一个空行

# 使用 lsb_release 获取额外的发行版信息
if command -v lsb_release &> /dev/null; then
    echo "LSB Release:"
    lsb_release -a
else
    echo "lsb_release command not found."
fi
echo ""  # 添加一个空行