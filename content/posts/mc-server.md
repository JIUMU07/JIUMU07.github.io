---
title: 用 ServerPackCreator 把 Minecraft 整合包客户端变成服务端
date: 2026-11-21
draft: false
categories: ["技术"]
tags: ["Minecraft", "整合包", "开服", "教程", "ServerPackCreator", "Forge", "Fabric"]
cover:
  image: "/images/covers/mc-server.jpg"
  alt: "Minecraft 整合包开服封面"
  credit: "Photo: Unsplash"
summary: 整合包只发客户端时，用 ServerPackCreator 直接生成服务端包：它会扫描 mod 的 sideness、自动排除纯客户端 mod，并生成启动脚本。本文只讲这一种方法，从下载、GUI/CLI 生成到启动、验证和更新。
---

有的大型整合包作者不愿意做服务端，这个时候就需要自己去将原本的客户端制作成服务端，而距离我上一次做 MC 服务端已经是上一次了，现在已经快忘了，所以趁现在还记得一点，尽快把制作步骤写下来，或许以后有用。

本文只推荐一种方法：**用 ServerPackCreator 从客户端整合包生成服务端包**，然后启动。它会把“哪些 mod 要留在服务端”这件事自动做掉，比自己一个个删靠谱。

## 一、先搞清三个概念

整合包里的 mod，按“跑在哪一侧”分三类：

| 类型 | 例子 | 服务端要不要 |
|---|---|---|
| **纯客户端** | Sodium、Iris、OptiFine、JEI、小地图、按键优化、光影 | **不要**，装了大概率崩或纯浪费 |
| **两侧都要** | 内容 mod（Create、农夫乐事）、库（Architectury、GeckoLib）、任务（FTB Quests）、KubeJS | **必须要**，而且版本要和客户端一致 |
| **可只服务端** | Chunky（预生成）、Spark（性能采样）、部分服务端优化 mod | 客户端不需要，但装了也不影响 |

ServerPackCreator 就是按这个分类，扫描每个 mod 的 metadata，把纯客户端的那部分从服务端包里剔掉。

## 二、下载 ServerPackCreator

项目地址：<https://github.com/Griefed/ServerPackCreator>（GPL-3.0），文档在 <https://serverpackcreator.de>。

到 **Releases** 页面下载：<https://github.com/Griefed/ServerPackCreator/releases>

两种形式，按自己的环境选：

| 形式 | 适合 | Java |
|---|---|---|
| **安装包**（Windows `.exe` / installer） | Windows 桌面，最省事 | **自带 Java**，不用另外装 |
| **`.jar`** | Linux、服务器、想用 CLI | 需要 **Java 21** |

> 官方明确说明：JAR 版本要求 Java 21；安装包自带 Java 运行时。

下载后：

- Windows 安装包：双击安装，用快捷方式启动；
- JAR：`java -jar ServerPackCreator-<版本>.jar`。

第一次启动会让你选一个 **home 目录**，之后配置、日志、生成的服务端包都放在那里：

```
<home>/
├── serverpackcreator.conf     # 默认配置
├── configs/                   # 每个整合包一份配置
├── server-packs/              # 生成出来的服务端包
└── logs/
```

有图形环境默认进 GUI（第一次会问要不要看 Step-by-Step 向导）；没有图形环境会自动进 CLI。

## 三、用 GUI 生成（推荐）

1. 启动 ServerPackCreator，选好 home 目录；
2. 在 **Server Pack Configuration** 里填：
   - **客户端整合包目录**：CurseForge / Prism / HMCL 的实例目录（里面有 `mods/`、`config/`）；
   - **Minecraft 版本**、**Modloader**（Forge / NeoForge / Fabric / Quilt / LegacyFabric）、**Modloader 版本**——多数情况下会自动识别；
3. **输出目录**：默认 `<home>/server-packs/`，可以改；
4. 确认 **Exclude clientside-only mods** 是开着的（默认开），它会自动扫描并排除纯客户端 mod；
5. 需要的话在 **Advanced** 里补：
   - 额外的排除/包含规则；
   - 启动脚本的内存参数（`-Xms` / `-Xmx`）和 Aikar flags；
   - **Install modloader server**（让 SPC 顺便把 Forge/Fabric 服务端装好，省一步）；
6. 点 **Generate**，看日志；
7. 完成后打开生成的目录（GUI 里可以直接跳过去）。

生成出来的目录大概长这样：

```
<home>/server-packs/<整合包名>/
├── mods/            # 已剔除纯客户端 mod
├── config/
├── scripts/         # 部分整合包会有
├── startserver.sh   # 或 startserver.bat / run.sh
└── libraries/       # 装了 modloader 才会有
```

## 四、用 CLI 生成（无桌面 / 服务器）

JAR 版本可以直接在命令行跑，适合把生成过程写进脚本。

**一条命令出包**（生成配置 + 生成服务端，一步到位）：

```bash
java -jar ServerPackCreator-<版本>.jar \
  -feelinglucky "/home/me/instances/MyPack" \
  --destination /srv/mc
```

**想先改配置再生成**：

```bash
# 1. 只生成配置
java -jar ServerPackCreator-<版本>.jar -cgen "/home/me/instances/MyPack"

# 2. 按日志里给出的配置路径打开并修改（排除列表、内存参数、是否安装 modloader 等）

# 3. 用配置生成
java -jar ServerPackCreator-<版本>.jar \
  -config "<配置文件的绝对路径>" \
  --destination /srv/mc
```

成功时最后一行类似：

```
Successfully generated Server Pack: /srv/mc/MyPack
```

> 服务器上没装 Java 21 的话，先装：`apt install openjdk-21-jre-headless`。

**注意**：无论你使用哪一种方式生成，都不一定能完美删除所有仅服务端的 mod，原因如下：

1. 新出的模组可能没被工具特征库收录，它没法识别。
2. 部分模组未在元数据中明确表示该模组只能客户端加载。
3. 部分模组客户端和服务端都有代码，但版本不匹配（比如客户端用 v1.2，服务端只支持 v1.1），这种“隐性不兼容”工具检测不出来。
4. 多模组之间的联动冲突，属于“组合问题”，不是单模组本身的问题，工具更没法预判。

遇到这种情况，建议先查看报错信息，再去 MC 百科查这个模组是否为仅服务端。注意报错里的模组名可能和 `mods` 文件夹里的名字不一样，建议搜索关键词。

## 五、确认 Java 版本

ServerPackCreator 自己需要 Java 21（安装包除外）；**生成出来的服务端**要按 MC 版本选 Java：

| MC 版本 | Java |
|---|---|
| 1.12 – 1.16.5 | Java 8 |
| 1.17 | Java 16（很多人直接用 17） |
| 1.18 – 1.20.4 | Java 17 |
| 1.20.5 – 1.21.x | Java 21 |

> 在 GUI 的 Advanced 里可以指定生成脚本使用的 Java 路径；版本不对，启动脚本会直接 `UnsupportedClassVersionError`。

## 六、启动生成的服务端

### 6.1 服务端核心从哪来

ServerPackCreator 生成的 ZIP 默认会把 Mojang 的 `server.jar` 排除掉（`serverpack.zip.exclude` 里包含 `server.jar`、`minecraft_server.<版本>.jar` 等），避免再分发。

所以从 ZIP 解压出来的服务端通常没有核心，核心是启动脚本第一次运行时下载/安装的：

- **Forge / NeoForge**：启动脚本用 ServerStarterJar 拉取对应版本的安装器并启动；
- **Fabric / Quilt / LegacyFabric**：启动脚本用对应的 installer 安装服务端；
- 如果在 SPC 生成时勾了 **Install modloader server**，核心会在生成阶段就装好，第一次启动不用再下。

所以第一次启动**需要联网**，并且能访问 Mojang / Forge / Fabric 的下载源；控制台会打印下载进度。

版本从生成目录的 `variables.txt`（或启动脚本顶部）看：

```
MINECRAFT_VERSION=1.20.1
MODLOADER=Forge
MODLOADER_VERSION=47.2.0
```

如果服务器不能联网，或者自动下载失败，就手动补核心——版本必须和上面三行一致：

| 核心 | 下载地址 | 怎么放 |
|---|---|---|
| 原版 `server.jar` | [Minecraft 官网](https://www.minecraft.net/en-us/download/server) | 放到服务端根目录，命名 `server.jar`（或脚本里引用的名字） |
| Forge | [files.minecraftforge.net](https://files.minecraftforge.net/) | 选同版本 installer，`java -jar forge-<版本>-installer.jar --installServer` |
| NeoForge | [neoforged.net](https://neoforged.net/) | 选同版本 installer，`--installServer` |
| Fabric | [fabricmc.net/use/server](https://fabricmc.net/use/server/) | 下载 installer，`java -jar fabric-server-mc...jar nogui` |
| Quilt | [quiltmc.org](https://quiltmc.org/) | 对应 installer |

> 手动装完 Forge/NeoForge 后，直接跑生成目录里的 `startserver.sh` 即可，脚本会复用已安装的核心。

### 6.2 进入目录，先看启动脚本

```bash
cd /srv/mc/MyPack
ls
```

有 `startserver.sh` / `startserver.bat` / `run.sh` 就直接用——SPC 生成时已经把内存参数写进去了。

```bash
./startserver.sh
```

Windows 双击 `startserver.bat`。

> 如果生成时没勾 **Install modloader server**，脚本可能还缺 Forge/Fabric 服务端本体；回 SPC 勾上重新生成一次即可，不用手动敲 installer。

### 6.3 同意 EULA

第一次启动会生成 `eula.txt` 并退出：

```bash
sed -i 's/eula=false/eula=true/' eula.txt
./startserver.sh
```

### 6.4 调 server.properties

```properties
online-mode=true
view-distance=8
simulation-distance=6
max-tick-time=-1
sync-chunk-writes=false
allow-flight=true
enable-command-block=true
spawn-protection=0
```

几个容易踩的：

- `online-mode=false` 只适合纯离线服，会带来冒名和 UUID 问题，公开服别关；
- `allow-flight=true`：有飞行坐骑之类的包必须开，否则会被判定飞行踢出；
- `max-tick-time=-1`：整合包启动/存档时单 tick 容易超时，关掉看门狗；
- `sync-chunk-writes=false`：提升性能，但异常断电可能丢最后一点区块数据，介意就别关。

### 6.5 内存与启动参数

两种改法：

- **生成前**：在 SPC 的 Advanced 里设 `-Xms` / `-Xmx`、Aikar flags；
- **生成后**：直接改 `startserver.sh` / `startserver.bat`，或 Forge 的 `user_jvm_args.txt`。

> 内存别把机器吃满：系统要留 1–2G。2C4G 的机器建议 `-Xmx3G` 以内，大包（300+ mod）至少 6–8G。

### 6.6 第一次启动看什么

看到这行才算成功：

```
Done (48.213s)! For help, type "help"
```

同时检查日志里有没有：

- `Missing or unsupported mandatory dependencies` → 缺库
- `NoClassDefFoundError: net/minecraft/client/...` → 还有客户端 mod 没排除干净
- `Exception in server tick loop` → 某个 mod 服务端 bug，看栈顶类名
- `Registry remapping failed` → 两边 mod 不一致

### 6.7 客户端连进来验证

客户端必须和服务器**同 MC 版本、同加载器版本、同 mod 列表（除纯客户端 mod）**：

1. 客户端用同一个整合包进单机，确认包本身没问题；
2. 连服务器，看是否能进、维度/任务/商店是否正常；
3. 让一个朋友用干净客户端连一次，排除本机缓存问题。

## 七、常见崩溃对照表

| 报错关键字 | 原因 | 处理 |
|---|---|---|
| `UnsupportedClassVersionError` | Java 版本不对 | 按第五节换 Java |
| `NoClassDefFoundError: net/minecraft/client/...` | 客户端 mod 漏排除 | 在 SPC 的排除列表里加上它，重新生成 |
| `Missing or unsupported mandatory dependencies` | 缺库/版本不符 | 按报错补 mod，注意版本 |
| `Incompatible mod set` / `Registry remapping failed` | 两边 mod 不一致 | 对比 `mods/` 列表和版本 |
| `Exception in server tick loop` | 某 mod 服务端 bug | 看栈顶类名，禁用该 mod 或升级 |
| `Address already in use` | 25565 被占 | `ss -lntp \| grep 25565` 找进程 |
| `Connection timed out` / `io.netty` | 端口/防火墙/穿透 | 查安全组、`ufw`、映射 |
| `KubeJS` 脚本报错 | 脚本用了客户端 API | 改脚本或删对应脚本 |
| `Datapack ... failed to load` | 数据包版本不对 | 换对应 MC 版本的数据包 |

## 八、网络：从局域网到公网

- 默认端口 **25565/TCP**；装了 Simple Voice Chat 再加 **24454/UDP**。
- 云服务器：安全组放行 + 系统防火墙（`ufw allow 25565/tcp`）。
- 家宽：有公网 IP 就做端口映射；没有公网 IP（CGNAT）就用 `playit.gg`、`frp`（需要一台公网服务器）或 EasyTier 之类组网。
- 公开服建议：`online-mode=true`、白名单、备份、别裸奔；被扫端口是常态。
- 离线服只给熟人：接受"谁都能冒充任意 ID"的风险，最好加登录插件/白名单。

## 九、性能：整合包服务端的三条经验

1. **单核性能比核数重要**。MC 主线程基本单核，2C4G 的云服务器能开中小包，但 300+ mod 的大包会明显卡。
2. **先降视距，再加内存**。`view-distance=8`、`simulation-distance=6` 往往比加 2G 内存更有效。
3. **预生成区块**。装个 Chunky（只装服务端），开服前把出生点周边 2000–5000 格跑一遍，能消掉大部分"跑图卡顿"。

排查卡顿用 Spark：

```
/spark profiler start
/spark profiler stop
```

> 不要给服务端装 OptiFine；服务端优化 mod（Lithium、FerriteCore、ModernFix、Canary、ServerCore）按需加，加之前看它是否声明支持你的加载器和版本。

## 十、长期维护

### 10.1 更新整合包

1. 停服，备份 `world/`、`config/`、`mods/`；
2. 用 ServerPackCreator 对新版客户端重新生成一份服务端包（换输出目录，别直接覆盖旧的）；
3. 对比新旧 `mods/`：新增的补上，删掉的移除，版本变了的替换；
4. 把旧服的 `world/` 和改过的 `config/` 迁到新包；
5. 启动看日志，确认 `Done` 后再放人进。

### 10.2 自动重启与备份

用 systemd 托管（Linux）：

```ini
[Unit]
Description=Minecraft Modpack Server
After=network.target

[Service]
User=mc
WorkingDirectory=/srv/mc/MyPack
ExecStart=/srv/mc/MyPack/startserver.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

备份脚本（每天凌晨，保留 7 天）：

```bash
#!/bin/bash
set -e
cd /srv/mc/MyPack
tar czf /backup/mc-$(date +%F).tar.gz world config mods kubejs server.properties
find /backup -name 'mc-*.tar.gz' -mtime +7 -delete
```

> 备份前最好让服务器 `save-off` + `save-all`，或者用支持热备份的工具，避免拿到半个区块。

### 10.3 版权与合规

- 整合包和 mod 都有授权协议，**别公开打包分发**别人的整合包；
- 不要开盗版服、不要绕过正版验证；
- 自己玩/小圈子私服没问题，公开运营要看清每个 mod 的 License。

## 十一、开服检查清单

- [ ] ServerPackCreator 生成成功，输出目录正确
- [ ] 纯客户端 mod 已被排除（没有 Sodium/Iris/OptiFine/JEI 这类）
- [ ] Java 版本匹配
- [ ] 依赖库已补齐
- [ ] `eula=true`
- [ ] `server.properties`：`online-mode`、`view-distance`、`allow-flight`、`max-tick-time`
- [ ] 启动日志出现 `Done`
- [ ] 25565/TCP（和 24454/UDP）已放行
- [ ] 客户端能进、能跑图、能开任务/商店
- [ ] 备份脚本 + 定时任务已配
- [ ] 白名单/OP 已设
- [ ] 重启服务器后能自动拉起

## 十二、我的建议

- 只用 **ServerPackCreator**：GUI 生成最省事，服务器上用 `-feelinglucky` 一条命令；
- 生成时勾上 **Exclude clientside-only mods**，再勾 **Install modloader server**，能省掉手动装 Forge/Fabric；
- 生成后仍然要实测——SPC 是“帮你生成”，不是“保证能开”；
- 每次整合包更新都重新生成一份，别在旧服务端上直接替换 `mods/`。

一句话总结：**让 ServerPackCreator 做“区分 mod”这件脏活，你只负责启动和调参。**
