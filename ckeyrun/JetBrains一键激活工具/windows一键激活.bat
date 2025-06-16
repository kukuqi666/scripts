@echo off
chcp 65001 >nul
title MarsCrack Windows 安装工具

echo ========================================
echo          MarsCrack 安装工具            
echo      JetBrains 系列产品激活工具        
echo ========================================
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ 错误：需要管理员权限！
    echo.
    echo 请右键点击此文件，选择 "以管理员身份运行"
    echo.
    pause
    exit /b 1
)

echo ✅ 管理员权限验证通过
echo.

:: 直接执行一键安装命令
echo 🔄 正在下载并安装 MarsCrack...
echo.

powershell -ExecutionPolicy Bypass -Command "irm ckey.run|iex"

if %errorLevel% equ 0 (
    echo.
    echo ✅ 安装完成！
) else (
    echo.
    echo ❌ 安装过程中出现错误
    echo.
    echo 如果问题持续存在，请：
    echo 1. 检查网络连接
    echo 2. 关注官方公众号获取帮助
    echo 3. 尝试手动运行以下命令：
    echo    irm ckey.run^|iex
)

echo.
pause 