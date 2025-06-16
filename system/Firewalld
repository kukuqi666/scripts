#!/bin/bash

# 打印帮助信息
print_help() {
    echo "作者：抖音海上森林一只猫"
    echo "联系方式：kukuqi666@gmail.com"
    echo "代码仓库：https://github.com/kukuqi666"
    echo
    echo "Usage: $0"
    echo "Select an option:"
    echo "1. Set Firewall to Startup on Boot"
    echo "2. Disable Firewall Startup on Boot"
    echo "3. Start Firewall"
    echo "4. Stop Firewall"
    echo "5. Check Firewall Status"
    echo "6. Check if Port is Open"
    echo "7. Allow Specific Port through Firewall"
    echo "8. List Open Ports"
    echo "9. List Docker Open Ports"
    echo "q. Quit"
}

# 设置防火墙开机自启
enable_firewall_startup() {
    systemctl enable firewalld >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Firewall set to startup on boot"
    else
        echo "Failed to set firewall startup on boot"
    fi
}

# 禁止防火墙开机自启
disable_firewall_startup() {
    systemctl disable firewalld >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Disabled firewall startup on boot"
    else
        echo "Failed to disable firewall startup on boot"
    fi
}

# 启动防火墙
start_firewall() {
    systemctl start firewalld >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Firewall started"
    else
        echo "Failed to start firewall"
    fi
}

# 停止防火墙
stop_firewall() {
    systemctl stop firewalld >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Firewall stopped"
    else
        echo "Failed to stop firewall"
    fi
}

# 查看防火墙状态
check_firewall_status() {
    status=$(systemctl status firewalld)
    if [[ $status == *"active (running)"* ]]; then
        echo "Firewall is active"
    elif [[ $status == *"inactive (dead)"* ]]; then
        echo "Firewall is inactive"
    else
        echo "Unable to determine firewall status"
    fi
}

# 查看端口是否开放
check_port_open() {
    read -p "Enter the port number to check: " port
    firewall-cmd --zone=public --query-port=$port/tcp
    if [ $? -eq 0 ]; then
        echo "Port $port is open"
    else
        echo "Port $port is not open"
    fi
}

# 允许指定端口通过防火墙
allow_port() {
    read -p "Enter the port number to allow: " port
    firewall-cmd --zone=public --add-port=$port/tcp --permanent >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Port $port allowed through firewall"
    else
        echo "Failed to allow port $port"
    fi
    firewall-cmd --reload
}

# 列出开放的端口
list_open_ports() {
    echo "Listing open ports:"
    firewall-cmd --list-ports
}

# 列出docker开放的端口
list_docker_open_ports() {
    echo "Listing open ports in the 'docker' zone:"
    firewall-cmd --zone=docker --list-ports
}

# 主逻辑
while true; do
    print_help
    read -p "Enter your choice: " choice

    case $choice in
        1)
            enable_firewall_startup
            ;;
        2)
            disable_firewall_startup
            ;;
        3)
            start_firewall
            ;;
        4)
            stop_firewall
            ;;
        5)
            check_firewall_status
            ;;
        6)
            check_port_open
            ;;
        7)
            allow_port
            ;;
        8)
            list_open_ports
            ;;
        9)
            list_docker_open_ports
            ;;
        q)
            exit 0
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac
done
