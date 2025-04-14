# docker/docker-install
Home of the script that lives at `get.docker.com` and `test.docker.com`!

The purpose of the install script is for a convenience for quickly
installing the latest Docker-CE releases on the supported linux
distros. It is not recommended to depend on this script for deployment
to production systems. For more thorough instructions for installing
on the supported distros, see the [install
instructions](https://docs.docker.com/engine/install/).

This repository is solely maintained by Docker, Inc.

## Usage:

From `https://get.docker.com`:
```shell
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

From `https://test.docker.com`:
```shell
curl -fsSL https://test.docker.com -o test-docker.sh
sh test-docker.sh
```

From the source repo (This will install latest from the `stable` channel):
```shell
sh install.sh
```

## Testing:

To verify that the install script works amongst the supported operating systems run:

```shell
make shellcheck
```

## 具体操作

这里分享的官方脚本默认安装了docker compose，也就是说执行这条命令后docker和docker compose都安装了，简化了安装步骤，非root用户记得使用sudo。

```
curl -fsSL https://get.docker.com | bash -s docker
```

    **curl -fsSL https://get.docker.com：从Docker的官方网站下载安装脚本。**
    **| bash -s docker：将前面curl命令下载的内容传递给bash（Bourne Again SHell）执行，并且传递docker作为参数给脚本。**

完了启动docker，顺便的话可以看一下docker的版本信息和服务状态
```
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker
```
注意看关键字段 Active: active (running)，表示 Docker 服务正在运行。

● docker.service - Docker Application Container Engine
     Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
     Active: active (running) since Sat 2024-06-01 12:34:56 UTC; 10min ago
       Docs: https://docs.docker.com
   Main PID: 12345 (dockerd)
      Tasks: 8
     Memory: 32.0M
     CGroup: /system.slice/docker.service
             └─12345 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock




如果你是国内的机器，线路不怎么好的话可以指定国内镜像源加快docker下载速度，你可以使用--mirror参数来指定镜像源，这里脚本配置 Docker 使用 Aliyun 的镜像源，可以避免因网络问题导致的下载速度慢或失败。

```
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
```


如果在中国或其他网络环境受限的地区，尝试使用国内的 Docker 镜像源来加速下载。例如，使用阿里云的 Docker 镜像源：
```
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://y1ncttng.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

阿里云镜像获取地址：https://cr.console.aliyun.com/cn-hangzhou/instances/mirrors



为了加快镜像的下载速度，我们可以将 Docker Hub 的镜像源修改为国内的镜像源。终端编辑此文件：
sudo vim /etc/docker/daemon.json

添加以下内容，然后保存退出！
```
{
    "registry-mirrors": [
        "https://docker.m.daocloud.io",
        "https://docker.nju.edu.cn",
        "https://dockerproxy.com",
        "https://dockerproxy.cn",
        "https://docker.1panel.live",
        "https://docker.hpcloud.cloud",
        "https://dockerpull.com",
        "https://docker.1ms.run",
        "https://y1ncttng.mirror.aliyuncs.com",
        "https://ypzju6vq.mirror.aliyuncs.com",
        "https://hub-mirror.c.163.com",
        "https://mirror.baidubce.com"
    ]
}

```


重启服务

```
systemctl daemon-reload
systemctl restart docker
```


运行以下命令以验证Docker是否正确安装
```
sudo docker run hello-world
```
该命令将下载一个测试镜像并在容器中运行。当容器运行时，它会打印出一条信息，说明Docker安装成功。



wsl2安装docker

接下来添加Docker源：
依次执行如下命令：
```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt update
```

配置完成软件源之后下一步是安装Docker，命令如下：

```
sudo apt install -y docker-ce
```


## 开启或关闭防火墙

要打开防火墙，请在终端输入 sudo ufw enable。要关闭 ufw，请输入 sudo ufw disable。
允许或阻止特定网络活动

很多程序专用于提供网络服务。例如，您可共享内容或允许其他人远程查看您的桌面。根据您安装的附加程序，您可能需要调整防火墙设置，以允许这些服务正常运行。UfW 附带了很多已预配置好的规则。例如，要允许 SSH 连接，请在终端输入 sudo ufw allow ssh。要阻止 ssh，请输入 sudo ufw block ssh。

提供服务的每个程序都使用特定的网络端口。要允许访问该程序的服务，您可能需要允许访问在防火墙上为其分配的端口。要允许连接端口 53，请在终端输入sudo ufw allow 53。要阻止端口 53，请输入 sudo ufw block 53。

要检查 ufw 的当前状态，请在终端输入 sudo ufw status。






启动docker2种方法

```
1.sudo service docker start   

  sudo service docker stop
  
  sudo service docker status


2.systemctl start docker

  systemctl stop docker

  systemctl restart docker

  systemctl status docker

  systemctl enable docker
```




查看docker信息

```
docker version
```

查看docker镜像

```
docker images
```

查看docker运行的容器(-a是指运行的所有容器)

```
docker ps -a
```

拉取nginx镜像  镜像后面不指定版本默认为latest

```
docker pull nginx 
```

保存nginx镜像  [镜像名]:[版本]

```
docker save -o nginx.tar nginx:latest
```

删除nginx镜像  [镜像名]:[版本]

```
docker rmi -f nginx:latest
```

恢复nginx镜像  [镜像名]:[版本]

```
docker load -i nginx:latest
```

如果没有拉取MySQL镜像 会执行拉取MySQL镜像然后创建一个mysql2(容器名)的容器
```
docker run -d \                      	#创建并运行一个容器，-d是让容器在后台运行
  --name mysql \					 	#给容器起个名字，必须唯一
  -p 3306:3306 \						#设置端口映射   [宿主机]:[容器内部]   宿主机端口映射到容器内端口
  -e TZ=Asia/Shanghai \					#KEY=VALUE   设置环境变量 
  -e MYSQL_ROOT_PASSWORD=123 \			
  mysql:latest							#指定运行镜像名字   [镜像名]:[版本]  默认latest可以省略，指定版本必须写
```

```
docker run -d --name mysql -p 3306:3306 -e TZ=Asia/Shanghai -e MYSQL_ROOT_PASSWORD=123456 mysql:latest							

docker run --name nginx -d -p 80:80 nginx:latest
```

停止容器  
```
docker stop mysql2
```
启动容器
```
docker start mysql
```
删除容器
```
docker rm -f mysql
```
查看nginx容器运行日志
```
docker logs -f nginx
```
进入nginx容器内部
```
docker exec -it nginx bash
```
进入MySQL并且连接
```
docker exec -it mysql mysql -uroot -p 
```
查看nginx容器内的ip
```
docker inspect nginx | grep IPAddress
```

配置命令的别名
```
vim ~/.bashrc
```
让 ./bashrc 生效
```
source ~./bashrc
```


今天在这里讲如何在docker上运行nignx镜像，并将配置文件和目录挂载到宿主机上，以实现方便统一的管理配置信息。

```
mkdir -p /usr/local/nginx/conf
mkdir -p /usr/local/nginx/logs
mkdir -p /usr/local/nginx/html
```

下面需要先运行容器，方便把文件本来的内容拷贝出来，然后再将容器删除，因为自己手动创建的配置文件容易有语法错误，当然如果你有了争取的配置文件也可以直接使用，就不需要创建容器拷贝出来后再删除这个操作了。接下来几个步骤可以跳过
	
### 1. 先用 nginx 镜像创建 nginx 容器，将需要挂载的文件拷贝出来

```
docker run --name nginx -d -p 80:80 nginx
```
 
### 2. 将容器中的 nginx.conf 文件拷贝到宿主机中

```
docker cp nginx:/etc/nginx/nginx.conf /usr/local/nginx/conf/nginx.conf
```
### 3. 将容器中 conf.d 文件夹（包括里面的文件）拷贝到宿主机中

```
docker cp nginx:/etc/nginx/conf.d /usr/local/nginx/conf/conf.d
 ```

### 4. 将容器中的 html 文件夹拷贝到宿主机中

```
docker cp nginx:/usr/share/nginx/html /usr/local/nginx/
```
 
### 5.删除正在运行的容器容器(-f 的参数作用是强制删除)

```
docker rm -f nginx
```

最终可以在宿主机中看到这些目录和文件夹，并且其中的html中包含了html文件，conf文件夹中包含了配置文件。


全部准备好后，做最终的文件夹挂载，端口映射

## 运行启动命令，并将端口进行映射，文件进行挂载。

```
docker run -p 80:80 --name nginx -v /usr/local/nginx/conf/nginx.conf:/etc/nginx/nginx.conf -v /usr/local/nginx/conf/conf.d:/etc/nginx/conf.d -v /usr/local/nginx/logs:/var/log/nginx -v /usr/local/nginx/html:/usr/share/nginx/html -d --restart=always nginx:latest
```

## 格式化后的代码
```
docker run -p 80:80 --name nginx \
-v /usr/local/nginx/conf/nginx.conf:/etc/nginx/nginx.conf \
-v /usr/local/nginx/conf/conf.d:/etc/nginx/conf.d \
-v /usr/local/nginx/logs:/var/log/nginx \
-v /usr/local/nginx/html:/usr/share/nginx/html \
-d \
--restart=always \
nginx:latest
 ```

 1.--name是设置容器名
 2.-p是容器与宿主机的端口映射
 3.-v是做卷挂载，实质上就是文件的映射
 4.-d是后台运行
 5.--restart 是Docker提供重启策略控制容器退出时或Docker重启时是否自动启动该容器。，always表示docker重启后，这个容器会自动重启

执行完成后，在浏览器查看是否可以访问。


以上就是docker运行nginx的所有步骤了，如果要配置ssl的话，需要先去域名申请证书，再配置到配置文件中，docker的操作步骤不影响。不过以上要注意几个问题

    容器的端口要映射出来才可以访问，如果是在阿里云服务器上，还需要把阿里云的对应的端口开通
    如果部署的是前端系统，需要把前端文件放到挂载的文件夹中，且nginx配置的访问路径是容器中对应的路径，不要配置成宿主机中的路径，否则会访问不到的
	
	
	
	
	


# ubuntu24.04安装docker												 
		
		
## 更新包信息	

```
sudo apt-get update          
apt list --upgradable            
sudo apt-get upgrade
```

## 安装docker必要依赖包

```
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common      
```

## 添加Docker的GPG密钥
```
curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
```

## 添加Docker的APT源

```
echo "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
```

## 更新包信息并安装Docker

```
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```






# 在使用 docker-compose up --build 时，Docker 会缓存之前的构建步骤，以加快构建速度。如果你想在构建过程中清除缓存


## 方法1：使用 --no-cache 选项 在运行 docker-compose up --build 时，添加 --no-cache 选项，Docker 将忽略所有缓存并重新构建镜像：

```
docker-compose up --build --no-cache
```

这将确保所有步骤从头开始重新构建，不会使用任何之前的缓存。


## 方法2：删除 Docker 构建缓存 你也可以手动清理 Docker 的构建缓存。可以使用以下命令来
 
```
docker builder prune
```

该命令会删除所有未使用的构建缓存。你会被提示确认是否继续清理，输入 y 确认。如果你想自动跳过确认提示，可以加上 -f 选项：

```
docker builder prune -f
```

## 方法3：清理具体的镜像和容器 如果你想手动删除已经构建的镜像和容器，也可以执行以下操作：

列出所有镜像 ：

```
docker images
```

删除某个镜像 （用 <image_id> 替换实际的镜像 ID）：

```
docker rmi <image_id>
```

删除所有未使用的镜像和容器 ：


```
docker system prune -a
```

这个命令不仅会删除未使用的镜像，还会删除停止的容器、未使用的网络等。 

## 总结

使用 --no-cache 选项强制重新构建：

```
docker-compose up --build --no-cache
```

使用 docker builder prune 清理构建缓存：

```
docker builder prune -f
```

使用 docker system prune -a 清理未使用的镜像和容器。 







# 在使用 docker-compose up --build 构建并启动服务后，后续的启动和关闭可以通过以下命令来管理：

## 启动和关闭服务的常用命令

  
首次启动 或需要重新构建时，使用 docker-compose up --build。
    
```
docker-compose up --build
```

正常启动 ：不需要重新构建时，只需运行以下命令：

```
docker-compose up
```

这将启动所有服务。加上 -d 选项可以在后台运行（即不显示日志）。

```
docker-compose up -d
```

关闭服务 你可以使用 docker-compose down 来停止并关闭所有容器：

```
docker-compose down
```

该命令会停止运行的容器，并清除与它们关联的网络。容器、网络、卷都会被移除。

停止服务 如果只想 停止服务 而不移除容器、网络等，可以使用：
 
```
docker-compose stop
```

这会停止所有正在运行的容器，但保留容器和网络的状态，以便以后可以快速重新启动。

重新启动服务 如果需要重新启动服务，可以运行以下命令：

```
docker-compose restart
```

如果需要仅重启某个服务，指定服务名称即可：

```
docker-compose restart <service_name>
```

## 启动和关闭总结

```
    启动服务 ：
        前台运行并构建： docker-compose up --build
        后台运行： docker-compose up -d

    关闭服务 ：
        完全关闭并清理： docker-compose down
        停止但不清理容器： docker-compose stop

    重新启动 ：
        重启所有服务： docker-compose restart
        重启特定服务： docker-compose restart <service_name>
```

通过这些命令，你可以灵活管理容器的启动、停止和重启。 
