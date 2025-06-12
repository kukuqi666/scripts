#!/bin/bash

# MarsCrack Mac/Linux 安装脚本
# 使用方法：bash install-mac.sh

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 显示标题
echo -e "${CYAN}========================================"
echo -e "         MarsCrack 安装工具            "  
echo -e "     JetBrains 系列产品激活工具        "
echo -e "========================================${NC}"
echo ""

# 检测系统类型
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo -e "${GREEN}✅ 检测到系统类型：${MACHINE}${NC}"
echo ""

# 一键安装命令配置

echo -e "${YELLOW}🔄 正在下载并安装 MarsCrack...${NC}"
echo ""

# 检查curl是否可用
if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}❌ 错误：未找到 curl 命令${NC}"
    echo ""
    echo -e "${YELLOW}请安装 curl：${NC}"
    echo -e "${WHITE}macOS: brew install curl${NC}"
    echo -e "${WHITE}Ubuntu/Debian: sudo apt-get install curl${NC}"
    echo -e "${WHITE}CentOS/RHEL: sudo yum install curl${NC}"
    echo ""
    exit 1
fi

# 直接执行一键安装命令
if curl -L -o ckey.run ckey.run && bash ckey.run; then
    echo ""
    echo -e "${GREEN}✅ MarsCrack 安装完成！${NC}"
    echo ""
    echo -e "${CYAN}📌 使用说明：${NC}"
    echo -e "${WHITE}1. 打开你的 JetBrains IDE${NC}"
    echo -e "${WHITE}2. 运行 MarsCrack 激活工具${NC}"
    echo -e "${WHITE}3. 按照提示完成激活${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  重要提示：${NC}"
    echo -e "${WHITE}- 请仅在合法授权范围内使用${NC}"
    echo -e "${WHITE}- 支持正版软件开发${NC}"
    echo ""
    
    # 清理临时文件
    rm -f ckey.run
else
    echo ""
    echo -e "${RED}❌ 下载或安装过程中出现错误${NC}"
    echo ""
    echo -e "${YELLOW}🔍 可能的解决方案：${NC}"
    echo -e "${WHITE}1. 检查网络连接${NC}"
    echo -e "${WHITE}2. 检查防火墙设置${NC}"
    echo -e "${WHITE}3. 关注官方公众号获取最新下载地址${NC}"
    echo -e "${WHITE}4. 手动运行：curl -L -o ckey.run ckey.run && bash ckey.run${NC}"
    echo ""
    # 清理临时文件
    rm -f ckey.run
    exit 1
fi

echo -e "${PURPLE}关注官方公众号【MarsCrack官方】获取更多支持${NC}"
echo ""

# Mac系统下的特殊提示
if [ "$MACHINE" = "Mac" ]; then
    echo -e "${YELLOW}💡 Mac用户提示：${NC}"
    echo -e "${WHITE}如遇到安全提示，请在 系统偏好设置 > 安全性与隐私 中允许运行${NC}"
    echo ""
fi

echo -e "${GREEN}安装完成！感谢使用 MarsCrack${NC}" 