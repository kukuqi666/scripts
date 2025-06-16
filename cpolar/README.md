## 1\. 安装cpolar内网穿透

Cpolar作为一款体积小巧却功能强大的内网穿透软件，不仅能够在多种环境和应用场景中发挥巨大作用，还能适应多种操作系统，应用最为广泛的Windows、macOS系统自不必多说，稍显小众的Linux、树莓派、群晖等也在支持之列，真正做到了广泛适用性。从这篇介绍开始，我们将会为大家详细介绍，cpolar在Linux系统下的各种应用类型。

Linux系统在桌面级应用范围较小，但却广泛应用于服务器级系统中。当然，为了保证服务器硬件资源都集中于数据交换和处理上，服务器级的Linux系统很少带有图形化界面，但基于Linux开发的Ubuntu系统，却拥有较为美观的图形化界面及与Windows相似的操作方式，是我们熟悉Linux系统的较好平台。

正如前面所说，Ubuntu系统虽然操作方法与Windows类似，都是以图形化为主，但在细节上还是有一定差别，其中就包括软件的安装方式。

### 1.1 安装cpolar

在Ubuntu上打开终端，执行命令

首先，我们需要安装curl：

```sehll
sudo apt-get install curl
```

+   国内安装（支持一键自动安装脚本）

```sehll
curl -L https://www.cpolar.com/static/downloads/install-release-cpolar.sh | sudo bash
```

![20230215174717](https://images.cpolar.com/img/20230215174717.png)

安装成功，如下界面所示

![20230215174738](https://images.cpolar.com/img/20230215174738.png)

+   或国外安装使用，通过短连接安装方式

```shell
curl -sL https://git.io/cpolar | sudo bash
```

### 1.2 正常显示版本号即安装成功

```shell
cpolar version
```

![20230215175043](https://images.cpolar.com/img/20230215175043.png)

### 1.3 token认证

登录[cpolar官网后台](https://dashboard.cpolar.com/get-started)，点击左侧的验证，查看自己的认证token，之后将token贴在命令行里

```shell
cpolar authtoken xxxxxxx
```

![20230215180429](https://images.cpolar.com/img/20230215180429.png)

![20230215175126](https://images.cpolar.com/img/20230215175126.png)

### 1.4 简单穿透测试一下

```shell
cpolar http 8080
```

![20230215175237](https://images.cpolar.com/img/20230215175237.png)

> 可以看到有正常生成相应的公网地址，测试穿透本地8080端口成功，按`Ctrl+C`返回

### 1.5 将cpolar配置为后台服务并开机自启动

```shell
sudo systemctl enable cpolar
```

![20230215181801](https://images.cpolar.com/img/20230215181801.png)

### 1.6 启动服务

```shell
sudo systemctl start cpolar
```

![20230215181825](https://images.cpolar.com/img/20230215181825.png)

### 1.7 查看服务状态

```shell
sudo systemctl status cpolar
```

正常显示为`active`，为正常在线状态

![20230215181857](https://images.cpolar.com/img/20230215181857.png)

### 1.8 登录cpolar Web UI管理界面

在浏览器上访问本地9200端口，【[127.0.0.1:9200](https://www.cpolar.com/blog/127.0.0.1:9200)】使用cpolar邮箱账号登录cpolar Web UI管理界面

![20230215175737](https://images.cpolar.com/img/20230215175737.png)

登陆成功,接下来就可以在Web UI界面创建隧道、编辑隧道、配置隧道、获取生成的公网地址，查看系统状态等操作了。

![20230215175759](https://images.cpolar.com/img/20230215175759.png)

* * *

## 2\. 搭建Web站点并发布到公网访问

**前言**

网：我们通常说的是互联网；站：可以理解成在互联网上的一个房子。把互联网看做一个城市，城市里面的每一个房子就是一个站点，房子里面放着你的资源，那如果有人想要访问你房子里面的东西怎么办？

在现实生活中，去别人家首先要知道别人的地址，某某区某某街道，几号，在互联网中也有地址的概念，就是IP。通过IP我们就能找到在互联网上面的站点，端口可以看做是这个房子的入口，不同的入口所看到的东西也就不一样，如从大门(80端口)进是客厅，从窗户(8080端口)进是书房。

接下来我们将通过简单几步来在Ubuntu搭建一个Web站点html小游戏，并使用cpolar内网穿透将其发布到公网上，使得公网用户也可以正常访问到本地Web站点的小游戏。

### 2.1 本地环境服务搭建

Apach2是一个服务，也可以看做一个容器，也就是上面说的房子，运行在Ubuntu里，这个服务可以帮助我们把我们自己的网站页面通过相应的端口让除本机以外的其他电脑访问。

下载Apach2

```shell
sudo apt install apache2 php -y
```

![20230215171101](https://images.cpolar.com/img/202310111045853.png)

下载好后启动Apache2

```shell
sudo service apache2 restart
```

然后打开Ubuntu浏览器，输入：[http://localhost](http://localhost/)。即可看到我们Apache默认的页面，此时说明本地站点已经搭建好了。

![·20230215171102](https://images.cpolar.com/img/202310111045442.png)

进入Apache默认服务器主目录路径，这个目录放的是想要让别人看到的资源，如一张图片、一个html页面等。

```shell
cd /var/www/html
```

进入后删掉index.html这个文件，由于Apache默认页面并不是我们自己想要的页面，我们想要换成自己喜欢的页面，所以需要删掉。执行以下命令:

```shell
sudo rm -rf index.html
```

为了达到测试效果，我们设置一个html页面小游戏，创建名称为`game.html`的页面

```shell
sudo vim game.html
```

按`i`键进入编辑模式，复制以下html代码进去(复制全部)

```shell
<!DOCTYPE html>
<html>
    <head><h4>Take it Easy!Please playing Game</h4></head>
    <body>
        <div></div>
        <!-- 4个board -->
        <div id="board1" style="position: absolute; width:80px; height:10px; left:420px; 
        top:555px; background-color: cadetblue;"></div>
        <div id="board2" style="position: absolute; width:80px; height:10px; left:520px; 
        top:555px; background-color: cadetblue;"></div>
        <div id="board3" style="position: absolute; width:80px; height:10px; left:620px; 
        top:555px; background-color: cadetblue;"></div>
        <div id="board4" style="position: absolute; width:80px; height:10px; left:720px; 
        top:555px; background-color: cadetblue;"></div>
        <!-- 小球 -->
        <div id="ball" class="circle" style="width:20px; 
        height:20px; background-color:crimson; border-radius: 50%; position:absolute; 
        left:600px; top:100px"></div>
        <!-- 框 -->
        <div id="box" style="border: 5px solid #555555; width:400px; height:550px; display=hide"></div>
        <!-- 分数 过的board越多，分数越高 -->
        <div id="score" style="width:200px; height:10px; position:absolute; left:900px; 
            font-family:'隶书'; font-size: 30px;">score: 0</div>
        <!-- 游戏结束 -->
        <div id="gg" style="width:200px; height:10px; position:absolute; left:550px; top:200px;
        font-family:'隶书'; font-size: 30px; display: none;">Game Over</div>
        <script>
            // 设置box的样式
            var box = document.getElementById("box");
            box.style.position = "absolute";
            box.style.left = "400px";
            // 设置board的样式
            var board1 = document.getElementById("board1");
            var board2 = document.getElementById("board2");
            var board3 = document.getElementById("board3");
            var board4 = document.getElementById("board4");
            // 声音
            var shengyin = new Audio();
            shengyin.src = "声音2.mp3";
            shengyinFlag = 0; // 用来表示小球在第几块board上
            // 键盘事件函数
            var ball = document.getElementById("ball");
            document.onkeydown = f;
            function f(e){
                var e = e || window.event;
                switch(e.keyCode){
                    case 37:
                        // 按下左键，小球左移，但不要超过左边框
                        if(ball.offsetLeft>=box.offsetLeft + 10)
                            ball.style.left = ball.offsetLeft - 8 + "px";
                        break;
                    case 39:
                        // 按下右键，小球右移，但不要超过由边框
                        if(ball.offsetLeft<=box.offsetLeft+box.offsetWidth-ball.offsetWidth-10)
                            ball.style.left = ball.offsetLeft + 8 + "px";
                        break;
                    case 32:

                }
            }
            // 定义一个分数变量
            var fenshu = 0;
            // 定义一个函数，移动给定的一个board
            function moveBoard(board)
            {
                var t1 = board.offsetTop;
                if(t1<=0)
                {
                    // 如果board移到最上面了，就随机换个水平位置，再移到最下面
                    t2 = Math.floor(Math.random() * (720- 420) + 420);
                    board.style.left = t2 + "px";
                    board.style.top = "555px";
                    fenshu += 1; //分数增加1
                    document.getElementById("score").innerHTML = "score " + fenshu;
                }
                    // 
                else
                    board.style.top = board.offsetTop - 1 + "px";
            }
            // 定义小球的速度变量
            var startSpeed = 1;
            var ballSpeed =startSpeed;
            // step函数是游戏界面的单位变化函数
            function step()
            {
                // board直接上下隔得太近，就逐个移动，否则，同时移动
                var t1 = Math.abs(board1.offsetTop - board2.offsetTop);
                var t2 = Math.abs(board2.offsetTop - board3.offsetTop);
                var t3 = Math.abs(board3.offsetTop - board4.offsetTop);
                // 定义一个board之间的间隔距离
                var t4 = 140;
                if(t1<t4)
                {
                    moveBoard(board1);
                }
                else if(t2<t4)
                {
                    moveBoard(board1);
                    moveBoard(board2);
                }
                else if(t3<t4)
                {
                    moveBoard(board1);
                    moveBoard(board2);
                    moveBoard(board3);
                }
                else
                {
                    moveBoard(board1);
                    moveBoard(board2);
                    moveBoard(board3);
                    moveBoard(board4);
                }
                // 定义小球的垂直移动规则，1、向下匀加速运动，2、如果碰到board就被board持续抬上去，
                // 直到按左右键离开了该board

                // 如果小球的纵坐标等于某个board的纵坐标，就被抬起
                var t5 = Math.abs(ball.offsetTop - board1.offsetTop);
                var t6 = Math.abs(ball.offsetTop - board2.offsetTop);
                var t7 = Math.abs(ball.offsetTop - board3.offsetTop);
                var t8 = Math.abs(ball.offsetTop - board4.offsetTop);
                if(t5<=ball.offsetHeight && t5>0 && ball.offsetLeft>=board1.offsetLeft-ball.offsetWidth && ball.offsetLeft<=board1.offsetLeft+board1.offsetWidth)
                {
                    ball.style.top = board1.offsetTop - ball.offsetHeight + "px";
                    ballSpeed = startSpeed;
                    if(shengyinFlag != 1)
                    {
                        shengyin.play();
                        shengyinFlag = 1;
                    }
                }
                else if(t6<=ball.offsetHeight && t6>0 && ball.offsetLeft>=board2.offsetLeft-ball.offsetWidth && ball.offsetLeft<=board2.offsetLeft+board2.offsetWidth)
                {
                    ball.style.top = board2.offsetTop - ball.offsetHeight + "px";
                    ballSpeed = startSpeed;
                    if(shengyinFlag != 2)
                    {
                        shengyin.play();
                        shengyinFlag = 2;
                    }
                }
                else if(t7<=ball.offsetHeight && t7>0 && ball.offsetLeft>=board3.offsetLeft-ball.offsetWidth && ball.offsetLeft<=board3.offsetLeft+board3.offsetWidth)
                {
                    ball.style.top = board3.offsetTop - ball.offsetHeight + "px";
                    ballSpeed = startSpeed;
                    if(shengyinFlag != 3)
                    {
                        shengyin.play();
                        shengyinFlag = 3;
                    }
                }
                else if(t8<=ball.offsetHeight && t8>0 && ball.offsetLeft>=board4.offsetLeft-ball.offsetWidth && ball.offsetLeft<=board4.offsetLeft+board4.offsetWidth)
                {
                    ball.style.top = board4.offsetTop - ball.offsetHeight + "px";
                    ballSpeed = startSpeed;
                    if(shengyinFlag != 4)
                    {   
                        shengyin.play();
                        shengyinFlag = 4;
                    }
                }
                else
                {
                    ballSpeed = ballSpeed + 0.01; // 数字相当于加速度
                    ball.style.top = ball.offsetTop + ballSpeed + "px";
                }
                // ballSpeed = ballSpeed + 0.01; // 数字相当于加速度
                // ball.style.top = ball.offsetTop + ballSpeed + "px";

                // 如果小球跑出来box，就结束游戏
                if(ball.offsetTop==0 || ball.offsetTop>=box.offsetTop+box.offsetHeight)
                {
                    clearInterval(gameover);
                    ball.style.display = 'none';
                    board1.style.display = 'none';
                    board2.style.display = 'none';
                    board3.style.display = 'none';
                    board4.style.display = 'none';
                    var gg = document.getElementById("gg"); //显示游戏结束
                    gg.style.display = 'block';
                }
            }

            var gameover = setInterval("step();", 8);
        </script>
    </body>
</html>
```

![20230215171103](https://images.cpolar.com/img/202310111045578.png)

> 复制完后按`Esc`键退出编辑，接着输入冒号`:wq`保存退出即可

### 2.2 局域网测试访问

接着浏览器输入[http://localhost/game.html](http://localhost/game.html)，即可看到html页面的小游戏站点，由于部署的是静态站点，不需要重启服务。

![20230215171104](https://images.cpolar.com/img/202310111045593.png)

### 2.3 内网穿透

由于这个站点目前只能在本地被访问到，为了使所有人都可以访问，我们需要将这个本地基础站点发布到公网。这里我们可以通过cpolar内网穿透工具来实现，它支持http/https/tcp协议，无需公网IP，也不用设置路由器，可以很容易将本地站点发布到公网供所有人访问。

#### 2.3.1 本地安装cpolar

如何在Ubuntu上安装cpolar内网穿透，请参考这篇文章教程

+   [Ubuntu用户安装Cpolar内网穿透](https://www.cpolar.com/blog/ubuntu-users-install-cpolar)

#### 2.3.2 创建隧道

cpolar安装成功之后，在浏览器上访问本地9200端口，登录cpolar Web UI管理界面。

![20230215171953](https://images.cpolar.com/img/202310111045906.png)

点击左侧仪表盘的隧道管理——创建隧道：

+   隧道名称：可自定义，注意不要重复
+   协议：http
+   本地地址：80
+   端口类型：随机域名
+   地区：China vip

点击`创建`

![20230215171105](https://images.cpolar.com/img/202310111045503.png)

隧道创建成功后，点击左侧的状态——在线隧道列表，可以看到刚刚创建的隧道已经有生成了相应的公网地址，将其复制下来，接下来测试访问一下。

![20230215171106](https://images.cpolar.com/img/202310111045468.png)

#### 2.3.3 测试公网访问

打开浏览器访问刚刚所复制的公网地址，注意：后面要加上路径/game.html，出现游戏界面即成功。

> 游戏控制使用:键盘上下左右键

![20230215171107](https://images.cpolar.com/img/202310111045180.png)

### 2.4 配置固定二级子域名

为了更好地演示，我们在前述过程中使用cpolar生成的隧道，其公网地址是随机生成的。

这种随机地址的优势在于建立速度快，可以立即使用。然而，它的缺点是网址由随机字符生成，不容易记忆（例如：3ad5da5.r10.cpolar.top）。另外，这个地址会在24小时内发生随机变化，更适合于临时使用。

在实际应用中我们一般会使用固定的二级子域名，因为我们希望将网址发送给领导、客户或同事时，它是一个固定的、容易记忆的、更专业的公网地址（例如：game.cpolar.cn），这样与（3ad5da5.r10.cpolar.top）相比更显正式，便于交流协作。

#### 2.4.1 保留一个二级子域名

登录cpolar官网后台，点击左侧的预留，找到保留二级子域名：

+   地区：选择China VIP
+   二级域名：可自定义填写
+   描述：即备注，可自定义填写

点击`保留`

![20230215171108](https://images.cpolar.com/img/202310111045771.png)

提示子域名保留成功，复制所保留的二级子域名

![20230215171109](https://images.cpolar.com/img/202310111045035.png)

#### 2.4.2 配置二级子域名

访问本地9200端口登录cpolar Web UI管理界面，点击左侧仪表盘的隧道管理——隧道列表，找到所要配置的隧道，点击右侧的编辑

![20230215171110](https://images.cpolar.com/img/202310111045911.png)

修改隧道信息，将保留成功的二级子域名配置到隧道中

+   域名类型：选择二级子域名
+   Sub Domain：填写保留成功的二级子域名，本例为test01

点击`更新`

![20230215171111](https://images.cpolar.com/img/202310111045882.png)

提示更新隧道成功，点击左侧仪表盘的状态——在线隧道列表，可以看到公网地址已经更新为保留成功的二级子域名，将其复制下来。

![20230215171112](https://images.cpolar.com/img/202310111045482.png)

#### 2.4.3 测试访问公网固定二级子域名

我们使用任意浏览器，输入刚刚配置成功的公网固定二级子域名+/game.html就可看到我们创建的站点小游戏了，且该地址不会再随机变化了。

![20230215171113](https://images.cpolar.com/img/202310111046270.png)

* * *

## 3\. 搭建网站：安装WordPress

在前面的介绍中，我们为大家展示了如何在Linux系统中安装cpolar，并对cpolar的Web-UI界面有了一些了解。接下来，我们可以根据实际案例，对cpolar的功能有更深刻的认识，甚至从中找到新的cpolar应用场景，让cpolar真正成为我们生活和工作的好帮手。现在，我们就结合本地网站发布到公网的情况，为大家介绍cpolar的数据隧道功能。

在以往，网站建设必须先租用网络服务器，再将网站内容和脚本上传服务器，再经过复杂配置，才能正式上线接受访客的访问。这一流程不仅复杂，还会产生不少开支。

但通过cpolar的数据隧道功能，可以将以往需要存在网络服务器上的数据和脚本放回本地电脑上，再使用cpolar建立的数据隧道，临时对网页上传后的效果进行测试；或者建立起稳定的隧道，省去租用网络服务器的开支。而想要在本地电脑上搭建网站，就必须先构建起网站的运行环境，以及对应的数据库。这里我们还是以WordPress为例（对使用者较为友好的建站软件）。

首先我们先安装网站所需的运行环境即数据库，我们可以在Ubuntu系统桌面，点击鼠标右键，并在菜单中点击“在终端中打开”，进入Ubuntu系统的命令行界面。

![20221118142851](https://images.cpolar.com/img/202310111046297.png)

![20221118142856](https://images.cpolar.com/img/202310111046375.png)

接着在命令行中输入命令，安装Apache2

```shell
sudo apt install apache2 php -y
```

![20221118142902](https://images.cpolar.com/img/202310111046249.png)

![20221118142907](https://images.cpolar.com/img/202310111046426.png)

在Apache2安装完成后，还需要安装数据库，才能支持WorePress网站的正常运行。同样的，我们在命令行窗口输入命令，安装MySQL数据库。

```shell
sudo apt install mariadb-server php-mysql -y
```

![20221118142913](https://images.cpolar.com/img/202310111046330.png)

![20221118142918](https://images.cpolar.com/img/202310111046771.png)

最后，我们就可以在命令行中输入WordPress的下载和安装。不过与Apache和MySQL不同，WordPress是网站运行的包合集，因此我们需要先将WordPress的压缩包下载到单独的文件夹，在解压后才能使用这些文件。

我们先输入命令，跳到Apache默认站点的根目录中

```sehll
cd /var/www/html
```

在该目录下输入命令，下载WordPress的压缩包

```shell
sudo wget http://wordpress.org/latest.tar.gz
```

![20221118142925](https://images.cpolar.com/img/202310111046138.png)

下载完成后，再输入命令解压

```shell
sudo tar xzf latest.tar.gz
```

看一下目录列表

```shell
ls
```

![20221118142930](https://images.cpolar.com/img/202310111046849.png)

解压完成后，我们需要将WordPress的文件移动到上级目录，输入命令移动所有文件。

```shell
sudo mv wordpress/* .
```

从顺序上来看，之前下载的WordPress压缩包就在这一层文件夹中（可以输入“ls”查看文件夹中的文件进行确认）。为防止干扰，我们可以将WordPress的压缩包删除，输入命令

```shell
sudo rm -rf wordpress latest.tar.gz
```

![20221118142937](https://images.cpolar.com/img/202310111046786.png)

再输入命令确认压缩包已经删除

```shell
ls
```

![20221118142944](https://images.cpolar.com/img/202310111046269.png)

接下来我们删除一下apche自带的静态页面

```shell
sudo rm index.html
```

![20221118142950](https://images.cpolar.com/img/202310111046528.png)

设置该wordpress 文件夹权限

```shell
sudo chown -R www-data: .
```

这条命令执行完成后，再输入命令，查看权限是否赋予成功。

```shell
ls -l
```

![20221118142957](https://images.cpolar.com/img/202310111046880.png)

然后接下来访问wordpress前，重启一下apache

```shell
sudo systemctl restart apache2
```

如上图所示，只要各文件名前显示出www，就说明我们的赋权操作已经完成。到这里，我们在Ubuntu上建立网站的软件都已经安装齐备，剩下的工作就是对这些软件进行相应的配置。

虽然配置过程不算复杂，但相对精细。为了能更清楚的说明配置过程，我们会在下一章节中为大家详细介绍。

* * *

## 4\. 搭建网站：创建WordPress数据库

在前面的文章中，我们向大家介绍了如何在Ubuntu系统中安装Apache2、MySQL、WordPress、cpolar几款软件，算是为我们的个人网站搭建打好了基础。但此时这些软件的状态是“安装上”，还不能直接启用，因此需要对软件进行相应的配置。现在，我们就来看看，如何对这些软件进行配置，使其能构建起网站运行的必要环境。

之前我们提到，WordPress网站想要正常运行，必须配备有相应的数据库，虽然我们安装了MySQL软件，但此时还没有建立其容纳数据的数据库，因此我们首先要对MySQL进行配置。由于数据库的设定涉及很多权限的确定，因此在这里需要小心，避免留下我们网站被入侵的漏洞。

初始化数据库,执行下面命令

```sehll
sudo mysql_secure_installation
```

![20221118143035](https://images.cpolar.com/img/202310111046754.png)

接着，mySQL会提出一系列问题，用以确定数据库的操作权限。这些问题的顺序分别为

1.  *要求root mysql数据库的密码（新安装的软件没有预置数据库，因此无密码，直接回车）；*
2.  \*切换到unix\_socket身份验证 \*
3.  *是否要设置root数据库的密码（会要求输入两次密码，密码一定要一致）；*
4.  *是否移动匿名账号；*
5.  *是否关闭root的远程登录；*
6.  *是否移除测试数据库；*
7.  *是否对修改内容重刷权限表；*

![image-20240605142345042](https://images.cpolar.com/img/202406051423535.png)

我们要注意，数据库的密码很重要，必须设置不易破解的密码，并且进行妥善记录防止遗忘。

完成这些步骤后，数据库的设置也就正式完成。

![20221118143042](https://images.cpolar.com/img/202310111046869.png)

接下来我们就着手创建一个WordPress专用的数据库，创建这个数据库的命令行为

```shell
sudo mysql -uroot -p
```

这条命令中，-u后直接连接（无空格）用户名，此处我们连接的是root用户，所以为-uroot，而-p则是用户密码。而MySQL也会要求输入用户密码和数据库密码。

![20221118143051](https://images.cpolar.com/img/202310111046200.png)

![20221118143056](https://images.cpolar.com/img/202310111046730.png)

登录数据库后,执行创建数据库命令,创建一个名称为wordpress数据库

```shell
create database wordpress;
```

![20221118143107](https://images.cpolar.com/img/202310111047605.png)

接着，输入命令为WordPress数据库进行权限设置（为防止输入命令时全角和半角错误，可以直接复制该命令）。

```shell
GRANT ALL PRIVILEGES ON wordpress.* TO 'root'@'localhost' IDENTIFIED BY '这里为你的root数据库密码';
```

![20221118143120](https://images.cpolar.com/img/202310111047469.png)

最后执行命令刷新一次。

```shell
flush privileges;
```

![20221118143128](https://images.cpolar.com/img/202310111047232.png)

由于一直处于命令行模式操作，并不如图形化操作直观，为确定我们的步骤没问题，我们可以输入命令确认我们成功建立起了WordPress专用数据库。

```shell
show databases;
```

![20221118143134](https://images.cpolar.com/img/202310111047948.png)

如上图所示，只要在反馈中出现了“WordPress”名称的数据库，就证明我们的设置步骤没错。  
最后，我们在Ubuntu的浏览器的地址栏中输入“localhost”（本机地址），就能打开我们熟悉的WordPress安装页面（如果浏览器没有显示WordPress安装页面，可以选择以隐私界面打开localhost，就能正常显示）。

![20221118143140](https://images.cpolar.com/img/202310111047931.png)

剩下的步骤都是常规设置，如显示语言、数据库设置、WordPress用户注册等等。这里需要注意的，就是WordPress数据库的设置，一定要和MySQL数据库中设置Wordpress数据库时所留的用户名及密码一致！（当然，当时我们设置的数据库名称就是wordpress）

![20221118143147](https://images.cpolar.com/img/202310111047229.png)

![20221118143152](https://images.cpolar.com/img/202310111047591.png)

完成这些设置后，我们就能正式进入WordPress的主界面了。

![20221118143158](https://images.cpolar.com/img/202310111047963.png)

至此，我们对WordPress网站的运行环境设置已经完成，剩下的就是如何使用cpolar，将位于本地的网站与公共互联网连接起来。而这部分内容，我们会在下一章节中，为大家详细介绍。

* * *

## 5\. 搭建网站：安装相对URL插件

通过前面几篇介绍中的范例，我们已经在Ubuntu系统中安装了WordPress网站运行所需的环境，并进行了相关配置。接下来，我们就可以正式进入网站的编辑流程，并通过cpolar将其发布到公共互联网上，接受互联网访客的访问。现在，就让我们开始吧。

要让本地的网页能为公共互联网的用户访问到，必须有符合现行互联网规范的地址，即URL。但WordPress本身并不自带生成URL地址的功能，我们必须通过为WordPress安装插件来实现这一功能。还是回到WordPress的主界面，在左侧我们能找到`插件`选项，点开后在搜索框输入`relative URL`，就能找到这款插件，接着点击安装启用即可。

![20221118143234](https://images.cpolar.com/img/202310111047462.png)

![20221118143240](https://images.cpolar.com/img/202310111047533.png)

完成URL插件的安装后，我们还需要对WordPress本身进行一项小修改，我们要教会WordPress正确应对外部访问请求，因此我们要打开Ubuntu命令行界面，输入命令，转入站点根目录

```shell
cd /var/www/html
```

转入站点根目录后，再输入命令对WordPress的配置文件进行编辑。

```shell
nano wp-config.php
```

![20221118143246](https://images.cpolar.com/img/202310111047701.png)

![20221118143251](https://images.cpolar.com/img/202310111048054.png)

在WordPress编辑界面，我们要找到如下位置，输入两行命令，分别为：

```php
define('WP_SITEURL', 'http://' . $_SERVER['HTTP_HOST']);
define('WP_HOME', 'http://' . $_SERVER['HTTP_HOST']);
```

由于命令行对于标点符号有全角半角的要求，因此最好还是复制命令，避免输入错误，导致WordPress运行错误。

![20221118143257](https://images.cpolar.com/img/202310111048291.png)

![20221118143303](https://images.cpolar.com/img/202310111048659.png)

确认命令输入无误后，就可以按快捷键`Ctrl+X`退出编辑，系统会询问我们是否保存更改，我们输入`Y`即可。

![20221118143308](https://images.cpolar.com/img/202310111048169.png)

如果我们要返回WordPress的设置界面，只要在浏览器中输入地址[http://localhost/wp-admin](http://localhost/wp-admin)，就能回到wordpress的仪表盘

![20221118143314](https://images.cpolar.com/img/202310111048499.png)

而我们也能在这里，选择自己喜欢的网站外观，打造自己心仪的网站。

![20221118143322](https://images.cpolar.com/img/202310111048895.png)

至此，我们在Ubuntu上搭建的网站就基本成型了。下一步，就是使用cpolar，将这个网站发布到公共互联网上，让更多人都能访问到这个网站。这部分内容，我们将在下一章节中，为大家详细说明。

* * *

## 6\. 搭建网站：内网穿透发布网站

通过前面介绍中的操作，我们已经成功的在Linux系统中搭建起网页运行所需的环境，并且通过WordPress成功制作了一个网页。但此时的网页还仅存在于本地电子设备上，想要将其发布到互联网上，还需要通过cpolar建立的数据隧道才能实现。今天，我们就尝试使用cpolar建立的数据隧道，让本地网页能够为互联网访客所访问的几种方法。

在此之前，我们已经在本地电脑上安装了cpolar，因此我们可以采用命令方式和图形化操作两种方式，建立起数据隧道。

### 6.1 命令行方式：

上面在本地成功部署了wordpress,并以本地127.0.0.1形式下访问成功,下面我们在Linux安装Cpolar内网穿透工具,通过Cpolar 转发本地端口映射的http公网地址,我们可以很容易实现远程访问,而无需自己注册域名购买云服务器.下面是安装cpolar步骤

> cpolar官网地址: [https://www.cpolar.com](https://www.cpolar.com/)

+   使用一键脚本安装命令

```shell
curl -L https://www.cpolar.com/static/downloads/install-release-cpolar.sh | sudo bash
```

+   安装完成后,可以通过如下方式来操作cpolar服务,首先执行加入系统服务设置开机启动,然后再启动服务

```shell
# 加入系统服务设置开机启动
sudo systemctl enable cpolar

# 启动cpolar服务
sudo systemctl start cpolar

# 重启cpolar服务
sudo systemctl restart cpolar

# 查看cpolar服务状态
sudo systemctl status cpolar

# 停止cpolar服务
sudo systemctl stop cpolar

```

Cpolar安装和成功启动服务后，内部或外部浏览器上通过局域网IP或者本机IP加9200端口即:【http://192.168.xxx.xxx:9200】访问Cpolar管理界面，使用Cpolar官网注册的账号登录,登录后即可看到cpolar web 配置界面,接下来在web 界面配置即可

![image-20240603142647836](https://images.cpolar.com/img/202406051128421.png)

### 6.2. 配置wordpress公网地址

点击左侧仪表盘的隧道管理——创建隧道，创建一个wordpress的公网http地址隧道!

+   隧道名称：可自定义命名，注意不要与已有的隧道名称重复
+   协议：选择http
+   本地地址：80 (默认是80端口)
+   域名类型：免费选择随机域名
+   地区：选择China vip

点击`创建`

![image-20240603142807481](https://images.cpolar.com/img/202406051129285.png)

隧道创建成功后，点击左侧的状态——在线隧道列表,查看所生成的公网访问地址，有两种访问方式,一种是http 和https,两种都可以访问,

![image-20240603142938891](https://images.cpolar.com/img/image-20240603142938891.png)

## 7\. 固定WordPress公网地址

由于以上使用cpolar所创建的隧道使用的是随机公网地址，24小时内会随机变化，不利于长期远程访问。因此我们可以为其配置二级子域名，该地址为固定地址，不会随机变化【ps：cpolar.cn已备案】

> 注意需要将cpolar套餐升级至基础套餐或以上，且每个套餐对应的带宽不一样。【cpolar.cn已备案】

[登录cpolar官网](https://dashboard.cpolar.com/)，点击左侧的预留，选择保留二级子域名，设置一个二级子域名名称，点击保留,保留成功后复制保留的二级子域名名称

![image-20240603180627086](https://images.cpolar.com/img/202406051129458.png)

保留成功后复制保留成功的二级子域名的名称

![image-20240603180656510](https://images.cpolar.com/img/202406051129671.png)

返回登录cpolar web UI管理界面，点击左侧仪表盘的隧道管理——隧道列表，找到所要配置的隧道，点击右侧的编辑

![image-20240603180737554](https://images.cpolar.com/img/202406051129624.png)

修改隧道信息，将保留成功的二级子域名配置到隧道中

+   域名类型：选择二级子域名
+   Sub Domain：填写保留成功的二级子域名

点击`更新`(注意,点击一次更新即可,不需要重复提交)

![image-20240603180818639](https://images.cpolar.com/img/202406051129427.png)

更新完成后,打开在线隧道列表,此时可以看到公网地址已经发生变化,地址二级名称变成了我们自己设置的二级子域名名称

![image-20240603180857948](https://images.cpolar.com/img/202406051129347.png)

### 7.1. 固定地址访问WordPress

最后,我们使用固定的公网http地址访问,可以看到同样访问成功,这样一个固定且永久不变的公网地址就设置好了,随时随地都可以远程访问我们的WordPress博客网站,无需公网IP,无需云服务器!

![image-20240603181058208](https://images.cpolar.com/img/202406051129347.png)

* * *

## 8\. 为网站配置自定义域名访问

通过之前的一系列的实例介绍，我们已经在Linux系统中创建了自己的网站，并且通过cpolar建立的数据隧道，将这个本地网站发布到公共互联网上，让公网访客也能轻松的访问到位于本地电子设备上的网站。不过，在某些特殊场合，特别是对于小型商务应用场景，会对网站的网址有一定要求（比如希望网站地址能体现自家公司名称或产品特色）。而这一点cpolar也能够通过一些设置满足需求。现在，就让我们看看如何使用cpolar，建立域名带有自身特色的数据隧道吧。

众所周知，网络域名（网址）是有限资源，对于一些特殊的网址，必须向域名供应商购买（对于如何购买自己想要的域名，我们已做过专门介绍，请翻阅本号文章）。假设我们已经购买了一个网址，如何设置才能让这个网址链接到本地的网页呢，这就要用到cpolar的自定义域名功能。

首先还是回到cpolar官网，在仪表盘左侧找到“预留”项，并在“预留”项找到“保留自定义域名”栏。在这个栏中，我们需要填入一些必要信息，包括“地区”、“要保留的域名（即购买的域名）”、以及这个域名的“备注”。这些信息填写完毕后，就能点击右侧的“保留”，生成一个专属的“CNAME”值。

![20221118143615](https://images.cpolar.com/img/202310111050474.png)

![20221118143620](https://images.cpolar.com/img/202310111050406.png)

接着我们回到域名供应商（此处以阿里云为例）的“域名列表”页面，在这个页面中，找到对应域名后的“解析”项，在跳出的域名“解析”设置卡中，在“记录类型”中选择“CNAME”类型，“主机记录”输入“WWW”，最后再将cpolar生成的“CNAME”值填入“记录值”框内。在相关信息填写完毕后，就可以点击下方的“确认”，保存所做的设置。由于域名供应商对所设置的域名解析需要一定时间（3-10分钟左右），我们可以在这段时间对本地cpolar客户端进行设置。

![20221118143626](https://images.cpolar.com/img/202310111050222.png)

![20221118143632](https://images.cpolar.com/img/202310111050788.png)

在等待域名供应商进行域名解析时，我们回到本地的cpolar客户端，将数据隧道的出口定位到本地网页的输出端口上，实现本地网页在公共互联网的发布。  
首先依旧是登录cpolar客户端，在客户端左侧找到“隧道管理”项，点击下拉菜单中的“隧道列表”。找到之前保留的二级子域名隧道（当然，我们也可以新建一条隧道，步骤都是一致的），点击右侧的“更新”按钮，对隧道进行重编辑。

![20221118143637](https://images.cpolar.com/img/202310111050316.png)

![20221118143642](https://images.cpolar.com/img/202310111050847.png)

在数据隧道重编辑页面，我们将“域名类型”重选为“自定义域名”，而“域名名称”则需要将所购买的域名粘贴进去。完成这些设置并且点击下方的“更新”按钮。

![20221118143647](https://images.cpolar.com/img/202310111050927.png)

![20221118143653](https://images.cpolar.com/img/202310111050581.png)

本地cpolar设置更改完成后，域名供应商对域名的解析也差不多完成了，此时我们就能使用所购买的域名，访问到本地网站。从以上介绍可以看出，cpolar对于自定义域名的设置并不复杂，仅需几分钟即可完成。当然，cpolar的功能并不仅限于此，如果您对cpolar的使用有任何疑问，欢迎与我们联系，我们必将为您提供力所能及的协助。当然也欢迎加入cpolar的VIP官方群，共同探索cpolar的无限潜能。

* * *

## 9\. 免费申请阿里云的SSL证书

通过之前一系列的操作，我们已经能够在Ubuntu系统上建立一个拥有特色网址（可以是公司名称，也可以是产品特色等等）的网站，并且通过cpolar创建的数据隧道，将其发布到公共互联网上，让公网访客能顺利的访问到这个网站。相信大家也发现，此时的网址还在使用http为网站前缀（即http协议），访客浏览器的网址前会显示“不安全网站”，让访问者有所顾忌，特别应用在商业网站时，很可能导致潜在客户流失。为了解决这个问题，我们必须为网站增加安全文件（即启用https协议），解除访客的后顾之忧。

![20221118143744](https://images.cpolar.com/img/202310111050467.png)

https与http协议之间，最主要的差别就是https协议添加了SSL层（加密数据层），不仅能建立起信息安全通道，还能据此判断网站的安全性。也正是这个原因，如果想要让我们的网站成为安全网站，就必须返回域名供应商处，取得域名的加密文件。

![20221118143750](https://images.cpolar.com/img/202310111050854.png)

在阿里云的“工作台”页面，我们能够找到“SSL证书”项，点击进入“SSL页面”（没有SSL证书项的，可以点击旁边的“添加”查询）。进入“SSL页面”后，点击左侧“SSL证书”，就能进入SSL证书申请和购买页面。

![20221118143756](https://images.cpolar.com/img/202310111051984.png)

![20221118143802](https://images.cpolar.com/img/202310111051745.png)

在SSL证书页面，我们找到“免费证书”选项卡，点击后再选择“立即购买”项

![20221118143809](https://images.cpolar.com/img/202310111051039.png)

每个账号可以获得20张免费证书，我们只需依照上图勾选相应选项，就可获得购买资格（虽是立即购买，但实际我们不必出钱即可获得）。购买完成后，我们的SSL证书页面就会有20份未签发的证书。

![20221118143817](https://images.cpolar.com/img/202310111051599.png)

接着，我们点击“创建证书”按钮，为我们已有的域名申请对应的SSL证书。

![20221118143822](https://images.cpolar.com/img/202310111051203.png)

![20221118143827](https://images.cpolar.com/img/202310111051307.png)

![20221118143836](https://images.cpolar.com/img/202310111051981.png)

首这里我们需要填写申请证书的域名相关信息，包括完整的域名、验证方式、域名地址、联系人等等（我们需要填写的，主要是完整域名、联系人、所在地信息），这些信息填写完毕后，就能点击下一步，进入验证信息设置。验证信息设置并不需要做什么，主要记住“记录类型”、“主机记录”、“记录值”三项信息，这三项信息是之后DNS验证时必填的信息。记好三项信息后，再点击“验证”按钮，在确认过信息后，就能点击最下方的“提交审核”。  
在证书审核通过后，我们返回阿里云的“工作台”，点击“云解析DNS”，在DNS解析页面选择“添加记录”，此时会弹出要求填入解析信息的信息框。

![20221118143842](https://images.cpolar.com/img/202310111051395.png)

![20221118143848](https://images.cpolar.com/img/202310111051802.png)

在“添加记录”的设置信息框内，我们填入SSL证书申请时获得的“记录类型”、“主机记录”、“记录值”几项信息。信息填入完毕后，点击下方的“确认”按钮。

![20221118143857](https://images.cpolar.com/img/202310111051835.png)

![20221118143901](https://images.cpolar.com/img/202310111051175.png)

在完成SSL证书审核资料填写，并递交申请后，我们只要静待审核通过即可。但需要注意的是，SSL证书的审核过程较为严格，并且需要耗费一定时间，因此我们必须保持手机畅通，及时查看邮件和短信，防止因疏忽导致证书审核失败。虽然看着各种信息资料眼花缭乱，但实际操作速度很快，只需要十余分钟就能填写提交完毕。

* * *

## 10\. 为网站配置SSL证书

在上篇介绍中，我们成功提交了SSL证书的实质性审核，在等待一段时间后，即可获得SSL证书审核通过的通知。但SSL证书并不会自行关联到我们本地的网站，因此需要我们自行对网站的SSL证书进行部署。

首先还是回到阿里云的“工作台”，进入SSL证书页面。可以看到我们关联的域名所申请的SSL证书已经获批，已经可以点击右侧的“下载”按钮。

![20221118143953](https://images.cpolar.com/img/202310111051178.png)

点击“下载”按钮后，会跳出证书格式选择的选项框，我们选择对应网页运行环境进行下载即可。

![20221118143957](https://images.cpolar.com/img/202310111051354.png)

当文件下载到本地后，我们将其解压到本地（一定要记得文件的解压位置），获得网站的密钥文件（后缀名为.key）和证书文件（后缀名为.pem）

![20221118144004](https://images.cpolar.com/img/202310111051631.png)

![20221118144009](https://images.cpolar.com/img/202310111051827.png)

![20221118144014](https://images.cpolar.com/img/202310111051498.png)

接着我们回到cpolar的Web-UI界面，点击“隧道管理”项下的“隧道列表”项，找到我们网站的数据隧道，点击“编辑”按钮，将证书匹配到本地网站上。这里需要注意“站点证书文件”需要上传.pem为后缀的文件，而“站点密钥文件”则上传后缀为.key的文件。上传完成后，点击下方的“更新”按钮，完成我们本地网站的证书上传工作。

![20221118144020](https://images.cpolar.com/img/202310111052160.png)

![20221118144025](https://images.cpolar.com/img/202310111052985.png)

为验证我们的网站是否已经是安全网站，我们可以在浏览器中输入使用https的网址，查看是否能够安全的访问到我们本地的网页。

![20221118144030](https://images.cpolar.com/img/202310111052367.png)

经过实测，我们已经可以使用https协议正确的访问到我们Ubuntu系统内的网页，也就说明我们对本地网页的安全配置正确，此时公网访客就可以安全放心的访问我们的网站了。当然，将本地网页发布到公共互联网上，仅仅是cpolar众多功能之一，而cpolar的其他功能的实现同样简便快捷。如果您对cpolar有任何疑问，欢迎与我们联系，我们必将为您提供力所能及的协助。当然也欢迎加入cpolar的VIP官方群，共同探索cpolar的无限潜能。

* * *

## 11\. SSH远程连接【同个局域网】

在之前的系列文章中，我们向大家详细介绍了如何在Linux系统中搭建一个像样的网站，并通过cpolar的数据隧道功能，将这个网站快速的发布到公共互联网的步骤。以相对简单的方式，将位于本地的网页发布到公共互联网上，只是cpolar众多功能中的一种，cpolar还可以轻松的实现很多其他功能，包括使用不同操作系统硬件间的轻松互联。现在，我们就向大家介绍，在Ubuntu系统下如何实现不同系统间的SSH连接（同一局域网环境）。

想要在Ubuntu系统下进行SSH连接（同一局域网环境），要先确认Ubuntu系统中有没有安装SSH。而确认方法也很简单，只要在Ubuntu的命令行窗口中输入命令  
“\`telnet 127.0.0.1 22“\`（其中127.0.0.1是本地电子设备的地址，而22是SSH专属的端口号），如果本地电子设备中安装了SSH，则会连接上该端口的设备；但如果没有安装SSH，则会显示如下信息：

![20221118144126](https://images.cpolar.com/img/202310111052316.png)

这时我们输入命令  
“\`sudo apt-get install openssh-server“\`要求系统安装SSH，并在命令确认时输入“y”，确定在Ubuntu系统中安装SSH。

![20221118144132](https://images.cpolar.com/img/202310111052915.png)

此时我们再输入最开始的查询命令  
“\`telnet 127.0.0.1 22“\`，就能看到Ubuntu系统已经显示出端口22的反馈信息（如果Ubuntu系统中安装了SSH，也会显示此信息）。

![20221118144138](https://images.cpolar.com/img/202310111052128.png)

想要让不同电子设备间形成数据连接，必须取得某一方的地址（即IP），才能让设备准确定位。这里我们选择查看Ubuntu系统的IP地址。只要在Ubuntu系统输入命令  
“\`ifconfig“\`，就能查询到该系统的IP地址（同一局域网下）。

![20221118144143](https://images.cpolar.com/img/202310111052902.png)

只要获得了Ubuntu设备的IP地址，我们就能在另一操作系统中（同一局域网下），输入Ubuntu设备的地址，就能查找到该设备，并进行连接。这里我们使用Windows系统，进行Ubuntu设备的连接尝试。在Windows的命令行窗口中输入  
“\`ssh (Ubuntu系统名称)@(Ubuntu的IP地址)“\`，命令，并在Windows系统询问是否连接时输入“\`yes“\`。需要注意的是，如果Ubuntu系统设定了系统密码，Windows系统在申请连接时，会要求输入该密码，以确保系统安全。

![20221118144149](https://images.cpolar.com/img/202310111052154.png)

只要在Windows命令行窗口中看到绿色字符的“XXX@Ubuntu：”提示行，就说明我们已经成功的在Windows系统上连接了Ubuntu系统，只要权限允许，我们可以通过命令行对Ubuntu系统进行操作。比如输入命令  
“\`ls“\`，就能看到Ubuntu系统中文件夹的设定。

![20221118144156](https://images.cpolar.com/img/202310111052490.png)

甚至更为复杂的操作，也能够通过命令行远程完成。但需要注意的是，这种方法只能在同一局域网下进行（比如同一家庭网络或办公室网络），如果在不同局域网间，这种连接方式就无效了。必须依靠cpolar建立的TCP数据隧道，才能实现在不同网络下的系统互连，我们将在下篇介绍中，为大家详细介绍如何在cpolar的帮助下，在公网环境实现不同系统之间的互联。

* * *

## 12\. 公网SSH远程连接

在上篇文章中，我们在Ubuntu系统中安装了SSH软件，并尝试在同一局域网下进行了不同设备间的互联。不过这种互联方式有较大局限性，就是两台硬件设备必须处于同一局域网环境下，才能进行连接。如果这两台设备不在同一环境下，就需要使用cpolar的TCP数据隧道功能。现在，就让我们来看看如何使用cpolar，让不同的硬件设备进行远程互联吧。

首先我们在Ubuntu系统下登录cpolar，在cpolar的Web-UI界面左侧找到“隧道管理”项，在下拉菜单中点击“创建隧道”。

![20221118144244](https://images.cpolar.com/img/202310111052197.png)

![20221118144249](https://images.cpolar.com/img/202310111052161.png)

这里我们需要对TCP隧道进行一些调整和设置：

+   对建立的TCP隧道进行命名，这里我们将隧道名称写为ssh（名称可自定义）；
+   数据协议选择“TCP”协议；
+   本地地址为端口22；
+   端口类型为可选择“临时TCP端口”。

在相关信息填写完毕后，即可点击下方的“创建”按钮，建立新的SSH隧道。

![20221118144255](https://images.cpolar.com/img/202310111052317.png)

在SSH隧道创建成功后，我们转回“在线隧道列表”界面，查看我们刚建立起的数据隧道相关信息。在这里，我们需要复制一段连接信息：“1.tcp.cpolar.io:XXXXX（XXXXX为数字端口号，每个隧道号码均不相同，前缀tcp://不必复制）”。

![20221118144301](https://images.cpolar.com/img/202310111052598.png)

再将这段链接信息粘贴到其他系统的命令行界面（此处我们依然使用windows系统），对应的命令为：

```shell
ssh -p XXXXX 用户名@1.tcp.cpolar.io
```

（其中，X为cpolar生成的端口号，用户名需替换为主机用户名）。需要注意的是，在数字端口号之前，一定要添加“（空格）-p（空格）”，否则无法连接隧道；其次是“ssh -p XXXXX 用户名@”之后，必须输入复制客户端生成的tcp地址。

在输入正确的连接命令后，Windows会出现两个提示信息，一是确认Ubuntu系统的连接提示信息，我们只要输入“yes”即可；二是要求输入Ubuntu系统密码（如果Ubuntu设置了密码）。在提示信息都通过后，Windows系统就会出现显示绿色字符的Ubuntu前缀命令行，也就意味着Windows系统已经连上Ubuntu系统，且不必担心Ubuntu系统是否处于同一局域网下。

![20221118144308](https://images.cpolar.com/img/202310111052834.png)

从上面的介绍可以看出，使用cpolar建立的数据隧道，能够轻松的将不同系统、不同网络环境的硬件连接起来，并能进行相应操作。不过此时的TCP连接还不是长期稳定存在（随机临时TCP连接），主要用于系统测试或临时远程连接解决某些问题。想要让这样的TCP连接状态长期稳定存续，我们还需要进行进一步的设置。关于如何设定长期稳定存在的TCP隧道，我们会在下一章节介绍中为大家详细说明。

* * *

## 13\. 为SSH远程配置固定的公网TCP端口地址

在上篇文章中，我们通过cpolar建立的临时TCP数据隧道，成功连接了位于其他局域网下的Ubuntu系统，实现了不同操作系统、不同网络下的系统互连，并能通过这条TCP连接隧道进行无差别操作。  
为了更好地演示，我们在前述过程中使用cpolar生成的TCP数据隧道，其端口号是随机生成的。

这种随机生成的端口号优势在于建立速度快，可以立即使用。然而，它的缺点是由随机字符生成，不容易记忆。另外，这个端口号会在24小时内发生随机变化，更适合于临时使用。

在实际应用中我们一般会使用固定的TCP数据隧道，因为我们希望将它发送给领导、客户或同事时，它是一个固定的、容易记忆的、更专业的，相比随机TCP隧道更显正式，便于交流协作的地址。

要建立一条稳定的TCP数据隧道，我们首先要登录cpolar官网，进入仪表台的“预留”界面

![20221118144407](https://images.cpolar.com/img/202310111052551.png)

![20221118144412](https://images.cpolar.com/img/202310111052080.png)

在预留界面中，找到“保留的TCP地址”项目。在这个项目下，我们填入一些必要信息，如识别数据隧道的隧道名称、隧道使用区域等。

![20221118144417](https://images.cpolar.com/img/202310111052524.png)

在这些信息填入后，点击右侧的“保留”按钮，将cpolar官网后台的隧道固定下来。此时cpolar会生成一个隧道端口，这就是我们连接到Ubuntu系统的“入口”（当然，这个隧道是双向的，此处只是方便说明作用）。

![20221118144422](https://images.cpolar.com/img/202310111052036.png)

接着我们回到Ubuntu系统下的cpolar界面，打开“隧道列表”，找到之前创建的随机临时TCP隧道，进入“编辑”页面，将我们在cpolar官网获得的隧道端口粘贴进“预留的TCP地址”栏中（此栏目只有点选“固定TCP端口”后才会出现）。在这些信息更改完毕后，就可以点击下方的“更新”按钮，将这条固定TCP隧道更新到Ubuntu系统下的cpolar客户端中。

![20221118144430](https://images.cpolar.com/img/202310111053450.png)

![20221118144436](https://images.cpolar.com/img/202310111053595.png)

此时，我们就可以在其他设备和操作系统下，使用命令，稳定轻松的连接到Ubuntu系统中，且不用再担心数据隧道端口号重置的问题。

```shell
ssh -p XXXXX 用户名@1.tcp.vip.cpolar.cn（X为cpolar生成的端口号，用户名替换为主机用户名）
```

当然，我们仍需要注意，在数字端口号之前，一定要添加`（空格）-p（空格）`，否则将无法连接隧道；其次在`ssh -p XXXXX 用户名@`之后，要输入复制cpolar生成的tcp地址。

![20221118144446](https://images.cpolar.com/img/202310111053935.png)

通过以上操作，我们已经能够长期稳定的使用cpolar建立的TCP数据隧道，在任意操作系统及网络环境下，连接到另一设备上，这一点对于电脑与树莓派、linux电脑或其他硬件设备的互联，都能带来极大便利。

* * *

## 14\. 使用VNC远程桌面

**前言**

实现Ubuntu系统桌面级别的远程连接，需要在Ubuntu系统中安装NVC。既然是桌面，前提是需要Ubuntu带有图形化界面，如果没有，可以执行以下命令安装图形化界面。

```shell
sudo apt install ubuntu-desktop 

sudo apt-get install gnome-panel gnome-settings-daemon metacity nautilus gnome-terminal 

sudo reboot #重启即可看到图形界面
```

### 14.1 Ubuntu安装VNC

在Ubuntu中安装VNC

```shell
sudo apt-get install x11vnc
```

![Image](https://images.cpolar.com/img/202310111053121.png)

安装LightDM【LightDM从设计上就是支持本地图形界面以获得最好的兼容性】

```shell
sudo apt-get install lightdm
```

安装过程中会出现以下选项，选择`lightdm`然后回车即可

![Image[1]](https://images.cpolar.com/img/202310111053170.png)

设置密码，设置密码后会问你是否需要将密码保存在:/home/root1/.vnc/passwd，输入`y`确认即可

```shell
x11vnc -storepasswd
```

![Image[2]](https://images.cpolar.com/img/202310111053058.png)

### 14.2 设置vnc开机启动

创建一个`x11vnc.service`文件

```shell
sudo vim /lib/systemd/system/x11vnc.service
```

按`i`键进入编辑模式，添加如下信息

> **!!注意: `<USERNAME>`替换为您ubuntu用户名**,添加完成后按Esc键退出编辑,然后输入冒号:wq保存

```shell
[Unit]
Description=Start x11vnc at startup.
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -auth guess -forever -loop -noxdamage -repeat -rfbauth /home/<USERNAME>/.vnc/passwd -rfbport 5900 -shared

[Install]
WantedBy=multi-user.target
```

![Image[3]](https://images.cpolar.com/img/202310111053113.png)

设置开机启动

```shell
sudo systemctl enable x11vnc.service
```

启动服务

```shell
sudo systemctl start x11vnc.service
```

### 14.3 windows 安装VNC viewer连接工具

进入VNC官网，下载Windows版VNC连接工具

> [https://www.realvnc.com/en/connect/download/viewer/](https://www.realvnc.com/en/connect/download/viewer/)

![Image[4]](https://images.cpolar.com/img/202310111053419.png)

下载好后打开使用局域网ip进行连接，端口是5900

![Image[5]](https://images.cpolar.com/img/202310111053407.png)

出现密码界面，输入上面设置的密码即可  
![Image[6]](https://images.cpolar.com/img/202310111053760.png)

出现Ubuntu桌面表示成功  
![Image[7]](https://images.cpolar.com/img/202310111053283.png)

### 14.4 内网穿透

本地测试远程连接没问题后，接下来我们实现在公网环境下的远程桌面，这里我们可以使用cpolar内网穿透工具实现程访问。cpolar支持http/https/tcp协议，不限制流量，无需公网ip，也无需设置路由器。

#### 14.4.1 安装cpolar【支持使用一键脚本命令安装】

+   cpolar 安装（国内使用）

```shell
curl -L https://www.cpolar.com/static/downloads/install-release-cpolar.sh | sudo bash
```

或cpolar短链接安装方式：(国外使用）

```shell
curl -sL https://git.io/cpolar | sudo bash
```

+   查看版本号，有正常显示版本号即为安装成功

```shell
cpolar version
```

+   token认证

登录cpolar官网后台，点击左侧的验证，查看自己的认证token之后将token贴在命令行里

```shell
cpolar authtoken xxxxxxx
```

![20230227141344](https://images.cpolar.com/img/202310111053499.png)

+   简单穿透测试，有正常生成相应的公网地址即为穿透成功

```shell
cpolar http 8080
```

按ctrl+c退出

+   向系统添加服务

```shell
sudo systemctl enable cpolar
```

+   启动cpolar服务

```shell
sudo systemctl start cpolar
```

+   查看服务状态

```shell
sudo systemctl status cpolar
```

#### 14.4.2 创建隧道映射

cpolar安装成功后，在浏览器上访问本地9200端口，【127.0.0.1:9200\]，使用cpolar邮箱账号登录 Web UI管理界面。

![Image[9]](https://images.cpolar.com/img/202310111053352.png)

登录成功后，点击左侧仪表盘的隧道管理——创建隧道，创建一个tcp协议的隧道指向本地5900端口:

+   隧道名称：可自定义，注意不要与已有的隧道名称重复
+   协议：tcp
+   本地地址：5900
+   域名类型：免费选择随机域名
+   地区：默认China top即可

点击`创建`

![Image[10]](https://images.cpolar.com/img/202310111053711.png)

隧道创建成功后，点击左侧的状态——在线隧道列表，可以看到，刚刚创建的隧道已经有生成了相应的公网地址+公网端口号，将其复制下来

![Image[11]](https://images.cpolar.com/img/202310111053296.png)

#### 14.4.3 测试公网远程访问

打开Windows VNC Viewer，使用刚刚所获取的公网地址+公网端口号进行连接。本例为`2.tcp.vip.cpolar.cn:13001`  
![Image[12]](https://images.cpolar.com/img/202310111054261.png)

输入密码  
![Image[13]](https://images.cpolar.com/img/202310111054834.png)

公网远程连接成功  
![Image[14]](https://images.cpolar.com/img/202310111054143.png)

### 14.5 配置固定TCP地址

为了更好地演示，我们在前述过程中使用cpolar生成的TCP数据隧道，其端口号是随机生成的。

这种随机生成的端口号优势在于建立速度快，可以立即使用。然而，它的缺点是由随机字符生成，不容易记忆。另外，这个端口号会在24小时内发生随机变化，更适合于临时使用。

在实际应用中我们一般会使用固定的TCP数据隧道，因为我们希望将它发送给领导、客户或同事时，它是一个固定的、容易记忆的、更专业的，相比随机TCP隧道更显正式，便于交流协作的地址。

#### 14.5.1 保留一个固定的公网TCP端口地址

登录cpolar官网后台，点击左侧的预留，选择保留的TCP地址。

+   地区：选择China VIP
+   描述：即备注，可自定义填写

点击保留

![Image[16]](https://images.cpolar.com/img/202310111054206.png)

地址保留成功后，系统会生成相应的固定公网地址，将其复制下来

![Image[17]](https://images.cpolar.com/img/202310111054136.png)

#### 14.5.2 配置固定公网TCP端口地址

在浏览器上登录cpolar Web UI管理界面，[http://127.0.0.1:9200/](http://127.0.0.1:9200/)，点击左侧仪表盘的隧道管理——隧道列表，找到我们前面创建的vnc远程隧道，点击右侧的编辑

![Image[18]](https://images.cpolar.com/img/202310111054040.png)

修改隧道信息，将保留成功的固定tcp地址配置到隧道中

+   端口类型：修改为固定tcp端口
+   预留的tcp地址：填写保留成功的地址

点击更新

![Image[19]](https://images.cpolar.com/img/202310111054998.png)

隧道更新成功后，点击左侧仪表盘的状态——在线隧道列表，找到VNC远程桌面隧道，可以看到公网地址已经更新成为了固定tcp地址。

![Image[20]](https://images.cpolar.com/img/202310111054705.png)

#### 14.5.3 测试使用固定公网地址远程

接下来测试使用固定TCP端口地址远程Ubuntu桌面，我们再次在Windows上打开VNC Viewer，使用固定tcp地址连接，出现密码界面，同样输入密码

![Image[21]](https://images.cpolar.com/img/202310111054516.png)

远程连接成功

![Image[22]](https://images.cpolar.com/img/202310111054213.png)

利用cpolar内网穿透软件，可以解决外网不可以访问内网资源的问题，让你轻松分享内网资源。并且cpolar基础套餐及以上的软件版本都带有固定公网TCP地址功能，这样就可以让你分享的网址更易记忆、也更加专业，可以让使用者更方便、快捷的与你同享内网资源。