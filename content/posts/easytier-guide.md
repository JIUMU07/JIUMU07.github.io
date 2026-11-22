---
title: 用 EasyTier 把服务器、电脑、手机组进同一个虚拟局域网
date: 2026-11-18
draft: false
categories: ["技术"]
tags: ["EasyTier", "内网穿透", "组网", "教程"]
cover:
  image: "/images/covers/easytier.jpg"
  alt: "EasyTier 虚拟局域网封面"
  credit: "Photo: Unsplash"
summary: EasyTier 是一个去中心化的异地组网工具，用一条命令就能把公网服务器、家里电脑和手机拉进同一个虚拟局域网。本文记录我在首尔服务器上搭中继节点的过程，以及 Windows、Linux、Android 客户端的使用方法和踩过的坑。
---

家里设备没有公网 IP、公司网络限制多、想随时 SSH 回服务器，这类需求用内网穿透工具能解决，但常见的方案要么要装客户端全家桶，要么要买中转带宽。EasyTier 是这两年里比较顺手的一个：Rust 写的、去中心化、支持 P2P 打洞和自建中继，配置也简单。

这篇文章分三部分：EasyTier 是什么、服务器上怎么搭一个中继节点、各平台客户端怎么连、以及我实际踩过的坑。

## 一、EasyTier 是什么

一句话：**把多台分布在世界各地的设备，组进同一个虚拟局域网，互相用内网 IP 访问。**

它和 ZeroTier、Tailscale 属于同类工具，几个特点：

| 特点 | 说明 |
|---|---|
| 去中心化 | 没有中心控制器，节点之间自己发现、自己打洞 |
| P2P 优先 | 能直连就直连；打不通才走中继（relay） |
| 跨平台 | Windows / macOS / Linux / Android / OpenWrt 都有 |
| 协议兼容 | 底层用 WireGuard，也支持 TCP / UDP / WebSocket / WSS 传输 |
| 自建中继 | 有公网服务器就能当 relay，不依赖官方节点 |
| 资源占用低 | 常驻几十 MB，2 核小机器完全够用 |

典型用途：

- 在外网 SSH / 访问家里 NAS、路由器后台、开发机；
- 多台云服务器组成内网，数据库只开内网端口；
- 手机、笔记本访问公司/家里的内网服务；
- 联机游戏走局域网模式。

## 二、这台服务器的角色：公网中继节点

我在首尔的轻量服务器上跑了一个 EasyTier 节点，配置是这样的：

| 项 | 值 |
|---|---|
| 版本 | EasyTier 2.6.4 |
| 运行方式 | systemd 常驻，服务名 `easytier` |
| 角色 | 中继 / 公共节点（`--no-tun`，不建虚拟网卡） |
| 监听端口 | TCP/UDP `11010`，WireGuard/WS `11011`，WSS `11012` |
| 虚拟网段 | `10.8.0.0/24`，服务器虚拟 IP `10.8.0.8` |
| 内存上限 | `MemoryMax=150M` |

> `--no-tun` 的意思是只做“中转站”，不把服务器当成出口路由。好处是不用 root 建虚拟网卡、对系统网络零侵入；坏处是别人不能通过它访问服务器所在的整个内网段。

## 三、服务器端：安装与配置

官方提供了一键脚本，也可以手动下二进制。

### 方式 A：一键脚本（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/EasyTier/EasyTier/main/script/install.sh | bash
```

装完会有 `easytier-core` 和 `easytier-cli` 两个命令。

### 方式 B：手动安装

```bash
mkdir -p /opt/easytier && cd /opt/easytier
# 从 GitHub Releases 下载对应架构的压缩包，例如 v2.6.4
# https://github.com/EasyTier/EasyTier/releases
unzip easytier-linux-x86_64-*.zip -d /opt/easytier
chmod +x /opt/easytier/easytier-core /opt/easytier/easytier-cli
```

### 配置 systemd

官方脚本会自动生成服务，但我想自己控制端口和内存，所以手写了一个：

```ini
[Unit]
Description=EasyTier relay/public node
After=network.target

[Service]
ExecStart=/opt/easytier/easytier-core --no-tun \
  --network-name jm-net-xxxx \
  --network-secret '<你的网络密钥>' \
  -l tcp://0.0.0.0:11010 \
  -l udp://0.0.0.0:11010 \
  -l wg://0.0.0.0:11011 \
  -l ws://0.0.0.0:11011 \
  -l wss://0.0.0.0:11012
Restart=always
RestartSec=3
MemoryMax=150M

[Install]
WantedBy=multi-user.target
```

```bash
systemctl daemon-reload
systemctl enable --now easytier
systemctl status easytier
```

> `--network-name` 和 `--network-secret` 相当于这个虚拟局域网的名字和密码，**所有客户端必须完全一致**。密钥不要发到公开仓库，我这个节点的真实密钥放在 `/opt/easytier/creds.txt`（权限 600）。

### 防火墙：必须放行端口

这一步最容易漏。腾讯云轻量服务器默认只开了 22/80/443，EasyTier 的端口要在**控制台防火墙**里手动加：

| 协议 | 端口 | 用途 |
|---|---|---|
| TCP | 11010 | 主连接 |
| UDP | 11010 | UDP 打洞 / 传输 |
| TCP | 11011 | WireGuard / WebSocket |
| TCP | 11012 | WSS |

如果机器上还开了 `ufw` 或 `firewalld`，本机也要放行：

```bash
ufw allow 11010/tcp
ufw allow 11010/udp
ufw allow 11011/tcp
ufw allow 11012/tcp
```

> 实测：只开 80/443 时，从外网连 `43.155.201.213:11010` 是**连不上的**，`easytier-cli peer` 里也永远只有自己。把端口放行后节点才能被外部客户端发现。

## 四、客户端怎么连

### Windows

下载 `easytier-gui`（Releases 里的 Windows 安装包），打开后填：

| 字段 | 值 |
|---|---|
| 网络名称 | 与服务端一致，例如 `jm-net-xxxx` |
| 网络密钥 | 与服务端一致 |
| 节点地址 | `tcp://43.155.201.213:11010` |

点「连接」，第一次会请求管理员权限（要建虚拟网卡 TUN），允许即可。

命令行版也可以：

```powershell
easytier-core -d --network-name jm-net-xxxx --network-secret "<密钥>" -p tcp://43.155.201.213:11010
```

### Linux

```bash
sudo easytier-core -d \
  --network-name jm-net-xxxx \
  --network-secret "<密钥>" \
  -p tcp://43.155.201.213:11010
```

`-d` 是守护进程模式；不加会前台运行，方便看日志。

### Android

安装 EasyTier 的 APK，新建配置：

- 网络名称 / 密钥同上；
- 添加对端节点：`tcp://43.155.201.213:11010`；
- 启动后手机会拿到 `10.8.0.x` 的虚拟 IP。

## 五、验证与使用

在任意一台客户端上：

```bash
# 看节点列表（能看到服务器和你的其他设备）
easytier-cli peer

# 看路由表
easytier-cli route

# 测试连通性
ping 10.8.0.8
```

`peer` 表里 `tunnel` 一列如果是 `tcp` / `udp` / `wg`，说明已经通了；`cost` 是链路开销，越小越优先。

然后就可以像局域网一样访问了：

```bash
ssh root@10.8.0.8
curl http://10.8.0.8:8000
```

我在服务器上跑的几个服务（小说、漫画、动漫、阅读引擎）都只监听 `127.0.0.1`，通过 EasyTier 连进来后，可以直接用 `10.8.0.8:端口` 访问，比暴露公网端口安全得多。

## 六、踩过的坑

1. **端口没放行，peer 里只有自己**
   控制台防火墙 + 本机 ufw 都要开，TCP 和 UDP 的 11010 缺一不可。

2. **连上了但延迟很高**
   `peer` 表里如果显示走的是中继而不是直连，说明 NAT 打洞失败。可以换 `udp` 传输、换端口，或者接受中继（延迟取决于服务器位置）。

3. **Windows 连不上 / 没有虚拟网卡**
   EasyTier 需要 TUN 驱动，必须用管理员身份运行；被安全软件拦了也会这样。

4. **两台设备的网段冲突**
   默认 `10.8.0.0/24`，如果家里路由器也是这个网段，会冲突。可以在服务端加 `-i 10.9.0.1/24` 之类换一个网段。

5. **`--no-tun` 不等于出口节点**
   它只是中继，不转发整个内网段。想让服务器当“出口”，要去掉 `--no-tun` 并配 `--enable-exit-node`（视版本而定），同时注意流量和安全。

6. **密钥泄露**
   网络名 + 密钥就等于入网凭证。密钥只放在服务端配置和客户端里，别提交到 git；一旦泄露，改密钥并重启所有节点。

## 七、命令速查

| 操作 | 命令 |
|---|---|
| 启动服务 | `systemctl start easytier` |
| 查看状态 | `systemctl status easytier` |
| 看日志 | `journalctl -u easytier -f` |
| 看节点 | `easytier-cli peer` |
| 看路由 | `easytier-cli route` |
| 前台调试 | `easytier-core --network-name ... --network-secret ...` |
| 测试端口 | `nc -vz 43.155.201.213 11010` |

## 八、小结

EasyTier 适合“有几台设备、想随时互访、又不想折腾 VPN 和公网 IP”的场景。自建一个公网中继节点的成本很低（一台 2 核小机器、几十 MB 内存），配置也就一条命令。

对我来说最实用的两个场景：

- 在外面用手机/笔记本直接访问服务器上只监听 `127.0.0.1` 的管理后台；
- 把多台云服务器拉进同一个内网，数据库、缓存只开内网端口。

如果你也有类似需求，照着上面的步骤搭一遍，十分钟就能跑起来。
