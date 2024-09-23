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
    sudo systemctl enable ufw >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Firewall set to startup on boot"
    else
        echo "Failed to set firewall startup on boot"
    fi
}

# 禁止防火墙开机自启
disable_firewall_startup() {
    sudo systemctl disable ufw >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Disabled firewall startup on boot"
    else
        echo "Failed to disable firewall startup on boot"
    fi
}

# 启动防火墙
start_firewall() {
    sudo ufw enable >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Firewall started"
    else
        echo "Failed to start firewall"
    fi
}

# 停止防火墙
stop_firewall() {
    sudo ufw disable >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Firewall stopped"
    else
        echo "Failed to stop firewall"
    fi
}

# 查看防火墙状态
check_firewall_status() {
    status=$(sudo ufw status)
	if [[ $status == *"状态： 激活"* ]]; then
		echo "Firewall is active"
	elif [[ $status == *"状态： 未激活"* ]]; then
		echo "Firewall is inactive"
	else
		echo "Unable to determine firewall status"
	fi

}

# 查看端口是否开放
check_port_open() {
    read -p "Enter the port number to check: " port
    sudo ufw status numbered | grep -q " $port " && echo "Port $port is open" || echo "Port $port is not open"
}

# 允许指定端口通过防火墙
allow_port() {
    read -p "Enter the port number to allow: " port
    sudo ufw allow $port >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Port $port allowed through firewall"
    else
        echo "Failed to allow port $port"
    fi
}

# 列出开放的端口
list_open_ports() {
     echo "Listing open ports:"
     sudo ufw status numbered
}

# 列出docker开放的端口
list_docker_open_ports() {
     echo "Listing open ports in the 'docker' zone:"
     # Docker 使用自定义的链，可能需要使用特定的命令来列出
     # 这里假设docker使用的是ufw来管理端口，实际情况可能需要根据具体配置来调整
     sudo ufw status | grep -i docker
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

