---
title: 来和我联机：用 EasyTier 加入我的虚拟局域网
date: 2026-11-25
draft: false
slug: easytier-join-me
categories: ["教程", "联机"]
tags: ["EasyTier", "虚拟局域网", "联机", "Minecraft", "内网穿透"]
ShowToc: true
cover:
  image: "/images/covers/easytier.jpg"
  alt: "EasyTier 联机封面"
  credit: "Photo: Unsplash"
summary: 给朋友看的 EasyTier 接入指南：装客户端、加入我的网络、确认虚拟 IP，然后像局域网一样连进我的游戏。网络密钥不公开，只私发。
---

想一起玩，但不想把游戏端口直接暴露到公网，也不想折腾端口映射？用 EasyTier 把我们的电脑组进同一个虚拟局域网就行。

这篇是给朋友看的操作版，不讲原理；想了解 EasyTier 怎么工作、怎么自建中继，可以看另一篇长文：[用 EasyTier 把服务器、电脑、手机组进同一个虚拟局域网](/posts/easytier-guide/)。

## 一、你会拿到什么

我会私发你两个东西：

| 项目 | 值 |
|---|---|
| 网络名 | `jm-net-o1dw` |
| 网络密钥 | **不公开，私发** |
| 中继节点 | `tcp://43.155.201.213:11010` |
| 我的节点名 | `hth` |
| 我的虚拟 IP | 固定为 `10.126.126.50`；朋友连接后以 `easytier-cli peer` 里 `hth` 的实际 IP 为准 |
| 游戏端口 | Minecraft 默认 `25565`；其他游戏以我发的端口为准 |

> 网络名 + 密钥就是入网凭证。密钥不要发到群里、GitHub 或公开文章里；泄露了告诉我，我换密钥。

## 先分清两个“服务器”

```text
朋友客户端
   │
   ├─ 初始节点：43.155.201.213:11010   ← EasyTier 中继/见面点
   │
   └─ 加入网络 jm-net-o1dw
          ├─ hth（我的游戏主机）：10.126.126.50
          ├─ 其他朋友：10.126.126.x
          └─ VM-0-8-ubuntu：中继节点（不负责开游戏）
```

- `43.155.201.213` 是让我们互相找到的**中继**，不是游戏服务器；
- 游戏服务跑在 `hth` 上，所以游戏地址填 `10.126.126.50`；
- 如果哪天我把游戏开到首尔服务器，地址才会变成服务器的虚拟 IP（如 `10.8.0.8`）。

## 二、安装 EasyTier

到官方 Releases 下载：

<https://github.com/EasyTier/EasyTier/releases>

不要从“高速下载站”下，认准 `EasyTier/EasyTier` 这个仓库。

### Windows

推荐装 `easytier-gui` 的 Windows 安装包；不想装 GUI 也可以直接用 CLI。

安装后第一次启动要允许管理员权限，因为 EasyTier 需要创建虚拟网卡（TUN）。**不给管理员权限就连不上。**

### Android

下载 APK 安装，打开后新建配置。手机端同样需要允许 VPN 权限。

## 三、加入我的网络

### 方式 A：GUI

打开 EasyTier GUI，新建一个网络，填：

| 字段 | 填什么 |
|---|---|
| 网络名称 | `jm-net-o1dw` |
| 网络密钥 | 我私发的那串 |
| 初始节点 | 类型 `tcp`；地址 `43.155.201.213`；端口 `11010` |
| 虚拟 IP | 朋友留空，自动分配；我这台固定为 `10.126.126.50/24` |

填完先点「保存配置」，再启动这个网络；状态从「已停止」变成运行中才算开始连接。

### 方式 B：命令行

Windows 在 EasyTier 目录打开 PowerShell：

```powershell
.\easytier-core.exe -d `
  --network-name jm-net-o1dw `
  --network-secret "<我私发的密钥>" `
  -p tcp://43.155.201.213:11010
```

Linux：

```bash
sudo easytier-core -d \
  --network-name jm-net-o1dw \
  --network-secret "<我私发的密钥>" \
  -p tcp://43.155.201.213:11010
```

`-d` 是后台运行；想现场看日志就去掉。

## 四、确认真的连上了

在 EasyTier 目录执行：

```powershell
.\easytier-cli.exe peer
```

正常情况下能看到：

- 我的节点 `hth`
- 中继节点 `VM-0-8-ubuntu`
- 你自己的节点

然后测试：

```powershell
ping 10.126.126.50
```

如果 `ping` 不通，先看第四节后面的排查。

也可以看路由：

```powershell
.\easytier-cli.exe route
```

## 五、连接游戏

确认能 ping 通我的虚拟 IP 后，在游戏里直接填这个地址：

### Minecraft Java 版

```text
服务器地址：10.126.126.50
端口：25565
```

### Minecraft 基岩版

```text
服务器地址：10.126.126.50
端口：19132
```

其他游戏用“局域网联机 / 直连 IP”的方式，地址填我的虚拟 IP，端口用我发你的那个。

> 如果 `peer` 里 `hth` 显示的 IP 不是 `10.126.126.50`，以你实际看到的为准；EasyTier 的虚拟 IP 可能因网络配置变化。

## 六、连不上怎么排查

### 0. 服务端日志提示 `network identity not match`

这不是端口问题，是**网络密码不一致**。到服务器确认当前密钥：

```bash
sudo grep '密钥' /opt/easytier/creds.txt
```

把 GUI 里的网络密码删掉重新粘贴，注意大小写和末尾空格。

### 1. `peer` 里只有自己

- 密钥或网络名打错；
- 中继地址写错；
- 你的网络/公司网络屏蔽了 TCP 11010。

先把中继改成：

```text
tcp://43.155.201.213:11010
```

还不行再试 UDP：

```text
udp://43.155.201.213:11010
```

### 2. 能连上但 ping 不通

- 先确认你连的是 `jm-net-o1dw`，不是别的网络；
- 看 `easytier-cli route` 里有没有对方路由；
- 虚拟 IP 冲突：如果你本地也用了 `10.126.126.0/24`，换一个网段；
- Windows 防火墙拦了 ICMP 或游戏端口。

### 3. 能 ping 通但游戏进不去

- 游戏服务没开，或者只监听了 `127.0.0.1`；
- 端口填错；
- 服务端防火墙没放行端口；
- Minecraft 版本/模组不一致。

### 4. 延迟很高

`peer` 里看链路是直连还是 `relay`。能直连最好；走中继延迟取决于中继服务器位置。可以换 UDP、换网络环境再试。

## 七、联机规矩

这是私人虚拟局域网，不是公共加速器：

- 只连游戏服务，不要扫我的其他端口；
- 不要把网络密钥转发给不认识的人；
- 不要用这个网络做攻击、扫描、穿透别人内网；
- 如果密钥泄露，告诉我，我会换掉并让所有人重连。

## 八、最短流程

```text
1. 下载 EasyTier（Windows GUI 或 CLI）
2. 以管理员身份运行
3. 网络名：jm-net-o1dw
4. 密钥：我私发
5. 中继：tcp://43.155.201.213:11010
6. easytier-cli peer 看到 hth
7. ping 10.126.126.50
8. 游戏里连 10.126.126.50:25565
```

就这些。卡在某一步，把 `easytier-cli peer` 的输出发我，不要发密钥。
