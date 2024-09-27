# openvpn-安装


适用于 Debian、Ubuntu、Fedora、CentOS、Arch Linux、Oracle Linux、Rocky Linux 和 AlmaLinux 的 OpenVPN 安装程序。

该脚本可让您在短短几秒钟内设置自己的安全 VPN 服务器。



## 用法

首先，获取脚本并使其可执行：

```
wget -O openvpn-install.sh https://raw.githubusercontent.com/kukuqi666/scripts/main/openvpn/install.sh
```

或

```
curl -O https://raw.githubusercontent.com/kukuqi666/scripts/main/openvpn/install.sh
```

赋予执行权限

```
chmod +x install.sh
```


然后运行它：

```
install.sh
```

您需要以 root 身份运行该脚本并启用 TUN 模块。

第一次运行它时，您必须跟随助手并回答几个问题来设置您的 VPN 服务器。

安装 OpenVPN 后，您可以再次运行该脚本，您将获得以下选择：

- 添加客户
- 删除客户端
- 卸载 OpenVPN

在您的主目录中，您将有“.ovpn”文件。这些是客户端配置文件。从您的服务器下载它们并使用您最喜欢的 OpenVPN 客户端进行连接。

如果您有任何疑问，请先前往[常见问题解答](#faq)。请在打开问题之前阅读所有内容。

**请不要向我发送电子邮件或私人消息寻求帮助。** 获得帮助的唯一地方是问题。其他人也许能够提供帮助，并且将来其他用户也可能会遇到与您相同的问题。我的时间不只是为你免费提供的，你并不特别。

### 无头安装

也可以无头运行脚本，例如无需等待用户输入，以自动方式。

用法示例：

````bash
AUTO_INSTALL=y ./openvpn-install.sh

＃ 或者
导出自动安装=y
./openvpn-install.sh
````

然后将通过传递用户输入的需要来设置一组默认变量。

如果您想自定义安装，可以导出它们或在同一行中指定它们，如上所示。

- `APPROVE_INSTALL=y`
- `APPROVE_IP=y`
- `IPV6_SUPPORT=n`
- `PORT_CHOICE=1`
- `协议选择=1`
- `DNS=1`
- `COMPRESSION_ENABLED=n`
- `CUSTOMIZE_ENC=n`
- `CLIENT=客户名称`
- `通过=1`

如果服务器位于 NAT 之后，您可以使用“ENDPOINT”变量指定其端点。如果端点是其后面的公共IP地址，您可以使用`ENDPOINT=$(curl -4 ifconfig.co)`（脚本将默认为此）。端点可以是 IPv4 或域。

可以根据您的选择设置其他变量（加密、压缩）。您可以在脚本的 installQuestions() 函数中搜索它们。

无头安装方法不支持受密码保护的客户端，因为 Easy-RSA 需要用户输入。

无头安装或多或少是幂等的，因为它可以安全地使用相同的参数多次运行，例如由 Ansible/Terraform/Salt/Chef/Puppet 等国家供应者提供。如果 Easy-RSA PKI 尚不存在，它只会安装并重新生成它；如果 OpenVPN 尚未安装，它只会安装 OpenVPN 和其他上游依赖项。它将在每次无头运行时重新创建所有本地配置并重新生成客户端文件。

### 无头用户添加

还可以自动添加新用户。这里的关键是在调用脚本之前提供“MENU_OPTION”变量的（字符串）值以及其余的强制变量。

以下 Bash 脚本将新用户“foo”添加到现有 OpenVPN 配置中

````bash
#!/bin/bash
导出MENU_OPTION =“1”
导出客户端=“foo”
导出通行证=“1”
./openvpn-install.sh
````

＃＃ 特征

- 安装并配置现成的 OpenVPN 服务器
- 以无缝方式管理 Iptables 规则和转发
- 如果需要，该脚本可以干净地删除 OpenVPN，包括配置和 iptables 规则
- 可自定义的加密设置，增强的默认设置（请参阅下面的[安全和加密](#security-and-encryption)）
- OpenVPN 2.4 功能，主要是加密改进（请参阅下面的[安全和加密](#security-and-encryption)）
- 推送给客户端的各种 DNS 解析器
- 选择使用带有 Unbound 的自托管解析器（支持现有的 Unbound 安装）
- TCP 和 UDP 之间的选择
- NAT IPv6 支持
- 默认情况下禁用压缩以防止 VORACLE。其他情况下也可使用 LZ4 (v1/v2) 和 LZ0 算法。
- 非特权模式：以“nobody”/“nogroup”身份运行
- 阻止 Windows 10 上的 DNS 泄漏
- 随机服务器证书名称
- 选择使用密码保护客户端（私钥加密）
- 许多其他小事情！

＃＃ 兼容性

该脚本支持以下 Linux 发行版：

|                    |支持|
| ------------------ | -------- |
| AlmaLinux 8 | ✅ |
|亚马逊 Linux 2 | ✅ |
| Arch Linux | ✅ |
| CentOS 7 | ✅ 🤖 |
| CentOS 流 >= 8 | ✅ 🤖 |
| Debian >= 10 | ✅ 🤖 |
|软呢帽 >= 35 | ✅ 🤖 |
|甲骨文 Linux 8 | ✅ |
|洛基 Linux 8 | ✅ |
| Ubuntu >= 18.04 | ✅ 🤖 |

需要注意的是：

- 该脚本定期针对仅标有 🤖 的发行版进行测试。
  - 仅在“amd64”架构上进行了测试。
- 它应该适用于旧版本，例如 Debian 8+、Ubuntu 16.04+ 和以前的 Fedora 版本。但上表中未列出的版本不受官方支持。
  - 它还应该支持 LTS 版本之间的版本，但这些版本尚未经过测试。
- 该脚本需要“systemd”。


＃＃ 常问问题

更多问答请参见[FAQ.md](FAQ.md)。

**问：** 您推荐哪家提供商？

**答：** 我推荐这些：

- [Vultr](https://www.vultr.com/?ref=8948982-8H)：全球位置，IPv6 支持，起价 5 美元/月
- [Hetzner](https://hetzner.cloud/?ref=ywtlvZsjgeDq)：德国、芬兰和美国。 IPv6，20 TB 流量，起价 4.5 欧元/月
- [Digital Ocean](https://m.do.co/c/ed0ba143fe53)：全球位置，IPv6 支持，起价 4 美元/月

---

**问：** 您推荐哪种 OpenVPN 客户端？

**答：** 如果可能的话，官方 OpenVPN 2.4 客户端。

- Windows：[官方 OpenVPN 社区客户端](https://openvpn.net/index.php/download/community-downloads.html)。
- Linux：您的发行版中的“openvpn”软件包。对于基于 Debian/Ubuntu 的发行版，有一个 [官方 APT 存储库](https://community.openvpn.net/openvpn/wiki/OpenvpnSoftwareRepos)。
- macOS：[Tunnelblick](https://tunnelblick.net/)、[Viscosity](https://www.sparklabs.com/viscosity/)、[OpenVPN for Mac](https://openvpn.net/client -connect-vpn-for-mac-os/)。
- Android：[Android 版 OpenVPN](https://play.google.com/store/apps/details?id=de.blinkt.openvpn)。
- iOS：[官方 OpenVPN Connect 客户端](https://itunes.apple.com/us/app/openvpn-connect/id590379981)。

---

**问：** 使用您的脚本可以安全地免受 NSA 的侵害吗？

**答：** 请检查您的威胁模型。即使此脚本考虑到安全性并使用最先进的加密，如果您想躲避 NSA，您也不应该使用 VPN。

---

**问：** 有 OpenVPN 文档吗？
**答：** 是的，请参阅[OpenVPN 手册](https://community.openvpn.net/openvpn/wiki/Openvpn24ManPage)，其中引用了所有选项。

---

更多问答请参见[FAQ.md](FAQ.md)。

## 公有云一站式解决方案

基于此脚本一次性提供现成可用的 OpenVPN 服务器的解决方案可用于：

- AWS 在 [`openvpn-terraform-install`](https://github.com/dumrauf/openvpn-terraform-install) 使用 Terraform
- Terraform AWS 模块 [`openvpn-ephemeral`](https://registry.terraform.io/modules/paulmarsicloud/openvpn-ephemeral/aws/latest)

## 贡献

## 讨论更改

如果您想讨论更改，尤其是重大更改，请在提交 PR 之前打开一个问题。

### 代码格式化

我们使用 [shellcheck](https://github.com/koalaman/shellcheck) 和 [shfmt](https://github.com/mvdan/sh) 来强制执行 bash 样式指南和良好实践。它们是通过 GitHub Actions 针对每个提交/PR 执行的，因此您可以在[此处](https://github.com/angristan/openvpn-install/blob/master/.github/workflows/push.yml)检查配置。

## 安全和加密

> **警告**
> OpenVPN 2.5 及更高版本尚未更新。

OpenVPN 的默认设置在加密方面相当薄弱。该脚本旨在改进这一点。

OpenVPN 2.4 是有关加密的重大更新。它增加了对 ECDSA、ECDH、AES GCM、NCP 和 tls-crypt 的支持。

如果您想了解有关下面提到的选项的更多信息，请参阅 [OpenVPN 手册](https://community.openvpn.net/openvpn/wiki/Openvpn24ManPage)。它非常完整。

OpenVPN 的大部分加密相关内容均由 [Easy-RSA](https://github.com/OpenVPN/easy-rsa) 管理。默认参数位于 [vars.example](https://github.com/OpenVPN/easy-rsa/blob/v3.0.7/easyrsa3/vars.example) 文件中。

＃＃＃ 压缩

默认情况下，OpenVPN 不启用压缩。该脚本提供对 LZ0 和 LZ4 (v1/v2) 算法的支持，后者效率更高。
然而，不鼓励使用压缩，因为 [VORACLE 攻击](https://protonvpn.com/blog/voracle-attack/) 利用了它。

### TLS 版本

OpenVPN 默认接受 TLS 1.0，该版本已有近 [20 年历史](https://en.wikipedia.org/wiki/Transport_Layer_Security#TLS_1.0)。

通过“tls-version-min 1.2”，我们强制执行 TLS 1.2，这是当前 OpenVPN 可用的最佳协议。

自 OpenVPN 2.3.3 起支持 TLS 1.2。

＃＃＃ 证书

OpenVPN 默认使用带有 2048 位密钥的 RSA 证书。

OpenVPN 2.4 添加了对 ECDSA 的支持。椭圆曲线加密更快、更轻、更安全。

该脚本提供：

- ECDSA：`prime256v1`/`secp384r1`/`secp521r1` 曲线
- RSA：`2048`/`3072`/`4096` 位密钥

它默认为带有“prime256v1”的 ECDSA。

OpenVPN 默认使用“SHA-256”作为签名哈希，脚本也是如此。到目前为止，它没有提供其他选择。

### 数据通道

默认情况下，OpenVPN 使用“BF-CBC”作为数据通道密码。 Blowfish 是一种古老的（1993 年）且较弱的算法。甚至 OpenVPN 官方文档也承认这一点。

> 默认为 BF-CBC，是密码块链接模式下 Blowfish 的缩写。
>
> 不再建议使用 BF-CBC，因为它的块大小为 64 位。正如 SWEET32 所证明的那样，这种较小的块大小允许基于冲突的攻击。有关详细信息，请参阅 <https://community.openvpn.net/openvpn/wiki/SWEET32>。
> INRIA 的安全研究人员发布了针对 64 位分组密码（例如 3DES 和 Blowfish）的攻击。他们表明，当相同的数据发送得足够频繁时，他们能够恢复明文，并展示他们如何利用跨站点脚本漏洞来足够频繁地发送感兴趣的数据。这适用于 HTTPS，也适用于 OpenVPN 上的 HTTP。请参阅 <https://sweet32.info/> 以获得更好、更详细的解释。
>
> OpenVPN 的默认密码 BF-CBC 受到此攻击的影响。
事实上，AES 是当今的标准。它是当今最快、更安全的密码。 [SEED](https://en.wikipedia.org/wiki/SEED) 和 [Camellia](<https://en.wikipedia.org/wiki/Camellia_(cipher)>) 迄今为止不易受到攻击，但速度较慢与 AES 相比，可信度相对较低。

> 在当前支持的密码中，OpenVPN 目前建议使用 AES-256-CBC 或 AES-128-CBC。 OpenVPN 2.4 及更高版本也将支持 GCM。对于 2.4+，我们建议使用 AES-256-GCM 或 AES-128-GCM。

AES-256 比 AES-128 慢 40%，并且没有任何真正的理由在 AES 中使用 256 位密钥而不是 128 位密钥。 （来源：[1](http://security.stackexchange.com/questions/14068/why-most-people-use-256-bit-encryption-instead-of-128-bit),[2](http: //security.stackexchange.com/questions/6141/amount-of-simple-operations-that-is-safely-out-of-reach-for-all- humanity/6149#6149))。此外，AES-256 更容易受到[计时攻击](https://en.wikipedia.org/wiki/Timing_attack)。

AES-GCM 是一种 [AEAD 密码](https://en.wikipedia.org/wiki/Authenticated_encryption)，这意味着它同时提供数据的机密性、完整性和真实性保证。

该脚本支持以下密码：

- `AES-128-GCM`
- `AES-192-GCM`
- `AES-256-GCM`
- `AES-128-CBC`
- `AES-192-CBC`
- `AES-256-CBC`

默认为“AES-128-GCM”。

OpenVPN 2.4 添加了一项名为“NCP”的功能：_可协商加密参数_。这意味着您可以提供类似于 HTTPS 的密码套件。默认情况下，它设置为“AES-256-GCM:AES-128-GCM”，并在与 OpenVPN 2.4 客户端一起使用时覆盖“--cipher”参数。为了简单起见，脚本将“--cipher”和“--ncp-cipher”设置为上面选择的密码。

### 控制通道

OpenVPN 2.4 将协商默认可用的最佳密码（例如 ECDHE+AES-256-GCM）

该脚本根据证书建议以下选项：

- ECDSA：
  - `TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256`
  - `TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384`
- RSA：
- `TLS-ECDHE-RSA-WITH-AES-128-GCM-SHA256`
  - `TLS-ECDHE-RSA-WITH-AES-256-GCM-SHA384`

默认为“TLS-ECDHE-*-WITH-AES-128-GCM-SHA256”。

### Diffie-Hellman 密钥交换

OpenVPN 默认使用 2048 位 DH 密钥。

OpenVPN 2.4 添加了对 ECDH 密钥的支持。椭圆曲线加密更快、更轻、更安全。

此外，生成经典 DH 密钥可能需要很长的时间。 ECDH 密钥是短暂的：它们是即时生成的。

该脚本提供以下选项：

- ECDH：`prime256v1`/`secp384r1`/`secp521r1` 曲线
- DH：`2048`/`3072`/`4096` 位密钥

默认为“prime256v1”。

### HMAC摘要算法

来自 OpenVPN wiki，关于“--auth”：

> 使用消息摘要算法 alg 通过 HMAC 验证数据通道数据包和（如果启用）tls-auth 控制通道数据包。 （默认为 SHA1 ）。 HMAC 是一种常用的消息身份验证算法 (MAC)，它使用数据字符串、安全哈希算法和密钥来生成数字签名。
>
> 如果选择 AEAD 密码模式（例如 GCM），则数据通道将忽略指定的 --auth 算法，而是使用 AEAD 密码的身份验证方法。请注意，alg 仍然指定用于 tls-auth 的摘要。

该脚本提供以下选择：

- `SHA256`
- `SHA384`
- `SHA512`

默认为“SHA256”。

### `tls-auth` 和 `tls-crypt`

来自 OpenVPN wiki，关于“tls-auth”：

> 在 TLS 控制通道之上添加额外的 HMAC 身份验证层，以减轻 DoS 攻击和对 TLS 堆栈的攻击。
>
> 简而言之，--tls-auth 在 OpenVPN 的 TCP/UDP 端口上启用一种“HMAC 防火墙”，其中带有不正确 HMAC 签名的 TLS 控制通道数据包可以立即丢弃而不会得到响应。

关于“tls-crypt”：

> 使用密钥文件中的密钥对所有控制通道数据包进行加密和验证。 （有关更多背景信息，请参阅 --tls-auth。）
>
> 加密（和验证）控制通道数据包：
>
> - 通过隐藏用于 TLS 连接的证书来提供更多隐私，
> - 使得识别 OpenVPN 流量变得更加困难，
> - 提供“穷人的”后量子安全，针对永远不知道预共享密钥的攻击者（即没有前向保密）。

因此，两者都提供了额外的安全层并减轻 DoS 攻击。 OpenVPN 默认情况下不使用它们。

`tls-crypt` 是 OpenVPN 2.4 的一项功能，除了身份验证之外，它还提供加密（与 `tls-auth` 不同）。它对隐私更加友好。

该脚本支持两者并默认使用“tls-crypt”。



## 积分和许可

非常感谢[贡献者](https://github.com/Angristan/OpenVPN-install/graphs/contributors) 和 Nyr 的原创作品。

该项目已获得[MIT许可证](https://raw.githubusercontent.com/Angristan/openvpn-install/master/LICENSE)

## 明星历史

[![明星历史图表](https://api.star-history.com/svg?repos=angristan/openvpn-install&type=Date)](https://star-history.com/#angristan/openvpn-install&Date ）
