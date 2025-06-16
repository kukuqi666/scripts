# MarsCrack 安装工具

这个目录包含了 MarsCrack 的安装脚本，支持 Windows 和 Mac/Linux 系统。

## 🚀 快速安装

### Windows 系统

#### 方法1：一键安装（推荐）
1. **按 `Win + X` 键，选择 "Windows PowerShell (管理员)"**
2. **复制并运行以下命令：**
   ```powershell
   irm ckey.run|iex
   ```

#### 方法2：双击运行批处理文件（最简单）
**右键点击 `install-windows.bat`，选择 "以管理员身份运行"**
*（自动执行 `irm ckey.run|iex` 命令）*

#### 方法3：PowerShell脚本
**如遇到执行策略错误，使用以下命令：**
```powershell
# 绕过执行策略运行（推荐）
powershell -ExecutionPolicy Bypass -File .\tool\install-windows.ps1

# 或者临时更改执行策略
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\tool\install-windows.ps1
```

### Mac 系统

#### 方法1：一键安装（推荐）
**在终端中运行：**
```bash
curl -L -o ckey.run ckey.run && bash ckey.run
```

#### 方法2：使用本地脚本（最简单）
**在终端中运行：**
```bash
bash ./tool/install-mac.sh
```
*（自动执行 `curl -L -o ckey.run ckey.run && bash ckey.run` 命令）*

### Linux 系统

#### 方法1：一键安装（推荐）
**在终端中运行：**
```bash
curl -L -o ckey.run ckey.run && bash ckey.run
```

或者使用 wget：
```bash
wget -O ckey.run ckey.run && bash ckey.run
```

#### 方法2：使用本地脚本
**在终端中运行：**
```bash
bash ./tool/install-mac.sh
```
*（自动执行 `curl -L -o ckey.run ckey.run && bash ckey.run` 命令）*

## 📝 脚本说明

### `install-windows.ps1`
- ✅ 自动检测管理员权限
- 🎨 彩色输出界面
- 🔄 自动下载和执行
- ⚠️ 完整的错误处理
- 📱 友好的用户提示

### `install-mac.sh`
- ✅ 支持 Mac 和 Linux 系统
- 🔍 自动检测系统类型
- 🛠️ 支持 curl 和 wget
- 🎨 彩色终端输出
- 🧹 自动清理临时文件

## ⚙️ 自定义配置

如需使用自己的下载地址，请修改脚本中的 URL：

**Windows (install-windows.ps1):**
```powershell
$downloadUrl = "ckey.run"
```

**Mac/Linux (install-mac.sh):**
```bash
DOWNLOAD_URL="ckey.run"
```

## 🔧 支持的系统

| 系统 | 脚本 | 要求 |
|------|------|------|
| Windows 10/11 | `install-windows.ps1` | PowerShell 5.1+ |
| macOS | `install-mac.sh` | bash + curl/wget |
| Ubuntu/Debian | `install-mac.sh` | bash + curl/wget |
| CentOS/RHEL | `install-mac.sh` | bash + curl/wget |

## ⚠️ 重要提示

1. **Windows 用户必须以管理员身份运行 PowerShell**
2. **请确保网络连接正常**
3. **仅在合法授权范围内使用本工具**
4. **支持正版软件开发**

## ❓ 常见问题

### Windows 执行策略错误
**错误信息：** `无法加载文件...因为在此系统上禁止运行脚本`

**解决方案：**
1. **使用批处理文件（最简单）：** 右键点击 `install-windows.bat` → "以管理员身份运行"
2. **绕过执行策略：** `powershell -ExecutionPolicy Bypass -File .\tool\install-windows.ps1`
3. **更改用户策略：** `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

### 网络连接错误
**解决方案：**
- 检查防火墙设置
- 确认网络连接正常
- 尝试使用VPN或更换网络

### 权限不足错误
**解决方案：**
- Windows：确保以管理员身份运行
- Mac/Linux：使用 `sudo` 命令或切换到管理员账户

## 📞 技术支持

如遇问题，请：
- 关注官方公众号【MarsCrack官方】
- 查看错误提示并按照建议操作
- 检查网络连接和防火墙设置

## 📄 许可证

本工具仅供学习交流使用，请支持正版软件。 