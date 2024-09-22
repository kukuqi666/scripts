# Installation
--------------------------------------------
File Browser is a single binary and can be used as a standalone executable. Although, some might prefer to use it with [Docker](https://www.docker.com/) or [Caddy](https://caddyserver.com/), which is a fantastic web server that enables HTTPS by default. Its installation is quite straightforward independently on which system you want to use.


# Quick Setup


--------------------------------------------

The quickest way for beginners to start using File Browser is by opening your terminal and executing the following commands:

### Brew

```
brew tap filebrowser/tap
brew install filebrowser
filebrowser -r /path/to/your/files
```

### Unix
```
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
filebrowser -r /path/to/your/files
```

### windows
```
iwr -useb https://raw.githubusercontent.com/filebrowser/get/master/get.ps1 | iex
filebrowser -r /path/to/your/files
```
------------------------------------------

Done! It will bootstrap a database in which all the configurations and users are stored. Now, you can see on your command line the address in which your instance is running. You just need to go to that URL and use the following credentials:

*   Username: `admin`
    
*   Password: `admin`
    

You must change the password and, if you can, the username for the best security possible.

Although this is the fastest way to bootstrap an instance, we recommend you to take a look at the possibility of options on [`config init`](https://filebrowser.org/cli/filebrowser-config-init) and [`config set`](https://filebrowser.org/cli/filebrowser-config-set) to make the installation as safe and customized as it can be.

[](about:blank#docker)
----------------------------------

# Docker

File Browser is also available as a Docker image. You can find it on [Docker Hub](https://hub.docker.com/r/filebrowser/filebrowser). The usage is as follows:

### alpine

```
docker run \
    -v /path/to/root:/srv \
    -v /path/filebrowser.db:/database.db \
    -v /path/.filebrowser.json:/.filebrowser.json \
    -u $(id -u):$(id -g) \
    -p 8080:80 \
    filebrowser/filebrowser
```

### linuxserver
```
docker run \
    -v /path/to/root:/srv \
    -v /path/to/filebrowser.db:/database/filebrowser.db \
    -v /path/to/settings.json:/config/settings.json \
    -e PUID=$(id -u) \
    -e PGID=$(id -g) \
    -p 8080:80 \
    filebrowser/filebrowser:s6
```
-----------------------------------------------

By default, we already have a [configuration file with some defaults](https://github.com/filebrowser/filebrowser/blob/master/docker/root/defaults/settings.json) so you can just mount the root and the database. Although you can overwrite by mounting a directory with a new config file. If you don't already have a database file, make sure to create a new empty file under the path you specified. Otherwise, Docker will create an empty folder instead of an empty file, resulting in an error when mounting the database into the container.




filebrowser 配置方法

创建配置数据库：filebrowser  config init

设置监听地址：filebrowser  config set --address 0.0.0.0

设置监听端口：filebrowser  config set --port 8088

设置语言环境：filebrowser  config set --locale zh-cn

设置日志位置：filebrowser  config set --log /var/log/filebrowser.log

添加一个用户：filebrowser  users add root password --perm.admin，其中的root和password分别是用户名和密码，根据自己的需求更改。

有关更多配置的选项，可以参考官方文档：https://filebrowser.org/

配置修改好以后，就可以启动 File Browser 了，使用-d参数指定配置数据库路径。示例：filebrowser -d /etc/filebrowser.db

启动成功就可以使用浏览器访问 File Browser 了，在浏览器输入 IP:端口，示例：http://192.168.1.1:8088

然后会看到 File Browser 的登陆界面，用刚刚创建的用户登陆。

登陆以后，默认会看到 File Browser 运行目录下的文件，需要更改一下当前用户的文件夹位置。

点击 [设置] → [用户设置] → 编辑用户 admin → 将目录范围改为你想要显示的文件夹，例如：/mnt → 修改完成后点击最下方的保存即可。

这样，File Browser 的基本安装和配置就搞定了。




后台运行

File Browser 默认是前台运行，如何让它后台运行呢？

第一种是 nohup 大法：

运行：nohup filebrowser -d /etc/filebrowser.db >/dev/null 2>&1 &

停止运行：kill -9 $(pidof filebrowser)

开机启动：sed -i '/exit 0/i\nohup filebrowser -d \/etc\/filebrowser.db >\/dev\/null 2>&1 &' /etc/rc.local

取消开机启动：sed -i '/nohup filebrowser -d \/etc\/filebrowser.db >\/dev\/null 2>&1 &/d' /etc/rc.local

第二种是 systemd 大法：

首先添加File Browser 的 service 文件：

```
[Unit]
Description=The filebrowser Process Manager
After=network.target

[Service]
Type=simple
ExecStart=/root/file/filebrowser -a 0.0.0.0
ExecStop=/bin/killall filebrowser
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

到/lib/systemd/system/filebrowser.service

如果你的运行命令不是/usr/local/bin/filebrowser -d /etc/filebrowser.db，需要对 service 文件进行修改，将文件的 ExecStart 改为你的运行命令，更改完成后需要输入systemctl daemon-reload。

运行：systemctl start filebrowser.service

停止运行：systemctl stop filebrowser.service

开机启动：systemctl enable filebrowser.service

取消开机启动：systemctl disable filebrowser.service

查看运行状态：systemctl status filebrowser.service

我推荐使用 systemd 的方法来后台运行，当然，前提是你所使用的操作系统支持 systemd。
HTTPS

File Browser 2.0 起开始内建 HTTPS 支持，只需要配置 SSL 证书即可。

配置 SSL：filebrowser -d /etc/filebrowser.db config set --cert example.com.crt --key example.com.key，其中example.com.crt和example.com.key分别是 SSL 证书和密钥路径，根据自身情况进行更改。配置完 SSL 后，只可以使用 HTTPS 访问，不可以使用 HTTP。

取消 SSL：filebrowser -d /etc/filebrowser.db config set --cert "" --key ""

当然，你也可以使用 Nginx 等 Web 服务器对 File Browser 进行反向代理，以达到 HTTPS 访问的目的。

还有就是使用 Caddy，这是一个开源、支持 HTTP/2 的 Web 服务器，它的一个显著特点就是默认启用 HTTPS 访问，会自己申请 SSL 证书，同时支持大量的插件，File Browser 就可以作为其插件运行。
外网访问

每个人的情况不同，外网访问的配置方法也不一样。

如果你有公网 IP 地址，不管是 v4 还是 v6，在防火墙上打开相应的端口以及设置好端口转发即可。

如果你没有公网IP地址，那么你想要外网访问可能就需要内网穿透了