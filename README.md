## 服务器连接方式

1 可以通过powershell连接

[!](images/powershell)

2 可以通过finalshell连接

[!](images/finalshell)

3 可以通过vscode插件连接

[!](images/vscode)





## filebrowser安装

```
linux

bash <(curl -s -L https://raw.githubusercontent.com/kukuqi666/scripts/main/filebrowser/install.sh)

curl -fsSL https://raw.githubusercontent.com/kukuqi666/scripts/main/filebrowser/get.sh | bash


windows

iwr -useb https://raw.githubusercontent.com/kukuqi666/scripts/main/filebrowser/get.ps1 | iex
```

## docker安装

```
bash <(curl -s -L https://raw.githubusercontent.com/kukuqi666/scripts/main/docker/install.sh)
```

##caddy安装

```
bash <(curl -s -L https://raw.githubusercontent.com/kukuqi666/scripts/main/caddy/install.sh)
```


## trojan-go安装

```
bash <(curl -sSL "https://raw.githubusercontent.com/kukuqi666/scripts/main/hj/trojan-go.sh")
```

## x-ui服务器管理面板安装

```
bash <(curl -Ls https://raw.githubusercontent.com/kukuqi666/scripts/main/x-ui/install.sh)
```

## xray安装

```
bash <(wget -qO- -o- https://raw.githubusercontent.com/kukuqi666/scripts/main/Xray-233boy/install.sh)
```


## v2ray安装

```
bash <(curl -s -L https://raw.githubusercontent.com/kukuqi666/scripts/main/v2ray-233boy/install.sh)

bash <(curl -s -L https://raw.githubusercontent.com/kukuqi666/scripts/main/v2ray-xyz690/install.sh)

bash <(curl -s -L https://raw.githubusercontent.com/kukuqi666/scripts/main/fhs-install-v2ray/install.sh)
```


## sing-box

```
bash <(curl -s -L https://raw.githubusercontent.com/kukuqi666/scripts/main/sing-box/install.sh)
```





## LNMP网站搭建一键安装脚本

```
wget http://soft.vpser.net/lnmp/lnmp2.1.tar.gz -cO lnmp2.1.tar.gz && tar zxf lnmp2.1.tar.gz && cd lnmp2.1 && ./install.sh lnmp
```


## screen使用方法

**install:**

ubuntu:apt install screen   centos: yum install screen



Attached：表示当前screen正在作为主终端使用，为活跃状态。

Detached：表示当前screen正在后台使用，为非激发状态。

通常情况下，不需要关注上面的状态。


screen -ls

即可查看已经创建（在后台运行的终端）



使用-R创建Hello

screen -R Hello

创建好虚拟终端后，运行你的程序（如：Springboot）：

screen内运行Spring

这个时候，我们按Ctril+a，再按d，即可保持这个screen到后台并回到主终端


使用screen -r命令

screen -r [pid/name]

其中：

pid/name：为虚拟终端PID或Name

其中：32307为PID，tool为Name。

回到这个虚拟终端的命令即为：

screen -r 32307

或(在没有重名虚拟终端情况下）

screen -r tool

另外一个-R和-r一样，但是没有对应名称的PID或者Name时，会自动创建新的虚拟终端。

退出终端

exit

之后，就会回到主终端。



当然，你如果对screen运行程序，确定已经停止运行了，也可以在主终端内，使用命令释放：
使用-R/-r/-S均可
screen -R [pid/Name] -X quit


使用nohup命令在后台运行程序，即使断开ssh连接也能保持运行：

touch nohup.out                                   # 首次运行需要新建日志文件  
nohup python3 app.py & tail -f nohup.out          # 在后台运行程序并通过日志输出二维码

扫码登录后程序即可运行于服务器后台，此时可通过 ctrl+c 关闭日志，不会影响后台程序的运行。在日志关闭后如果想要再次打开只需输入 tail -f nohup.out。
(5) 停止程序

如果想要关闭程序可以 执行 kill -9 <pid>来完成，执行以下命令可以查看当前进程的 pid：

ps -ef | grep app.py | grep -v grep


kill
在查到端口占用的进程后，如果你要杀掉对应的进程可以使用 kill 命令：

kill -9 PID
如上实例，我们看到 8000 端口对应的 PID 为 26993，使用以下命令杀死进程：

kill -9 26993