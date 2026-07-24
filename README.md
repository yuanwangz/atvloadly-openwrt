# atvloadly-openwrt

让 OpenWrt 路由器在局域网内直接为 Apple TV 安装和自动续签 IPA。

不需要 VPS、Tailscale、Docker 或外接存储。路由器只持久保存程序、Apple ID 会话和 Apple TV 配对信息；IPA 仅在安装或续签时下载到 `/tmp` 内存盘，完成后自动清理。

> 适用目标：`aarch64_cortex-a53`、musl 的 OpenWrt 路由器。安装前请先确认路由器的 `/tmp` 至少有 250 MB 可用空间。

## 它如何工作

```text
IPA 发布地址（例如 GitHub Release）
              │ 仅在任务开始时下载
              ▼
OpenWrt 路由器上的 atvloadly
  ├─ 保存 IPA URL、Apple ID 会话、Apple TV 配对信息
  ├─ 内置定时续签任务
  └─ 按需启动 plumesign 重签和安装
              │
              ▼
          Apple TV
```

首次安装、手动刷新和自动续签均使用同一个远程 URL。URL 对应的 IPA 更新后，下一次刷新会自动使用新版本；路由器不会把 IPA 保存到闪存。

## 1. 修复路由器 DNS

OpenWrt 的 `/etc/resolv.conf` 应由网络服务自动生成，不能手工写死为空文件。以下命令为 WAN 配置两个可靠的 DNS，并保留默认的局域网 DNS 转发行为：

```sh
ssh root@192.168.31.1

uci set network.wan.peerdns='0'
uci -q delete network.wan.dns
uci add_list network.wan.dns='223.5.5.5'
uci add_list network.wan.dns='119.29.29.29'
uci commit network
/etc/init.d/network reload

nslookup github.com
```

网络重载时 SSH 可能短暂断开，重新连接即可。最后一条命令能返回 GitHub 的地址即表示 DNS 正常。

无需为 `15533` 单独开放 WAN 防火墙端口；OpenWrt 默认允许局域网访问路由器本机服务。不要把管理页面暴露到公网。

## 2. 下载并安装

从本项目的 **Releases** 下载 `atvloadly-openwrt-aarch64.tar.gz` 和同名 `.sha256` 文件。将二者上传到路由器的 `/tmp`：

```sh
scp atvloadly-openwrt-aarch64.tar.gz root@192.168.31.1:/tmp/
scp atvloadly-openwrt-aarch64.tar.gz.sha256 root@192.168.31.1:/tmp/

ssh root@192.168.31.1
cd /tmp
sha256sum -c atvloadly-openwrt-aarch64.tar.gz.sha256
tar -xzf atvloadly-openwrt-aarch64.tar.gz
cd atvloadly-openwrt
./install.sh
```

安装脚本会完成以下工作：

- 将两个静态二进制写入 `/opt/atvloadly/bin`；
- 创建仅 root 可读写的数据目录；
- 写入并启用 OpenWrt 开机服务；
- 把临时目录固定为 `/tmp/atvloadly`；
- 配置大 IPA 签名期间临时的内存保护策略，并在任务结束后自动恢复。

安装后，在同一局域网浏览器打开：`http://192.168.31.1:15533`。

## 3. 首次配对和安装

1. 确保 Apple TV 与路由器处于同一局域网。
2. 在页面中发现并配对 Apple TV；这是首次操作，配对信息会被持久保存。
3. 首次使用时，打开“设置 → 高级 → 更新 CoreADI”，等待运行库下载并提取完成。
4. 登录 Apple ID。若 Apple 要求双重验证，按页面提示完成验证。
5. 使用应用安装页面的 **URL** 输入框填写 IPA 的直接下载地址，而不是上传本地 IPA。
6. 安装后保持该应用的自动刷新开关启用。

推荐使用稳定地址，例如：

```text
https://github.com/<owner>/<repo>/releases/latest/download/VidPlayPlus-tvOS-development.ipa
```

该 URL 必须能由路由器匿名直接下载。GitHub 私有 Release 需要额外鉴权，不能直接作为本版本的远程 IPA 源。

CoreADI 更新会临时下载 Apple Music APK 并仅持久保留所需运行库；该过程不把 Apple 的运行库打进本项目的公开发布包。

## 4. 自动续签与更新

`atvloadly` 自带调度器，不需要设置路由器 cron。默认在应用到期前一天的凌晨时段执行刷新；可在网页设置中调整提前天数和时间。

每次刷新时会依次：

1. 从保存的远程 URL 下载 IPA 到 `/tmp/atvloadly`；
2. 重签并通过局域网安装到 Apple TV；
3. 删除 IPA、签名工作目录、安装日志和临时缓存；
4. 记录最新有效期与刷新结果。

发布新版应用时，只需将新版 IPA 发布到同一个稳定 URL。路由器无需再次上传或修改配置。

## 日常维护

查看服务和临时空间：

```sh
/etc/init.d/atvloadly status
logread -e atvloadly
df -h /overlay /tmp
```

升级本项目时，解压新安装包后再次执行 `./install.sh`。已有 Apple ID 会话、配对信息、远程 IPA URL 和应用记录都会保留。

如需完全卸载：

```sh
cd /tmp/atvloadly-openwrt
./uninstall.sh
```

卸载会删除 `/opt/atvloadly` 中的会话、配对数据和应用设置。

## 构建产物

每次推送都会通过 GitHub Actions 构建：

- 静态 musl `atvloadly`，使用纯 Go mDNS，不依赖 Avahi 或 D-Bus；
- 静态 musl、支持 RSD 的 `plumesign`；
- 经 UPX `--best --lzma` 压缩并通过完整性校验的 OpenWrt 安装包。

普通推送可在 Actions 的构建产物中下载；推送 `v*` 标签会创建 GitHub Release。

## 常见问题

**自动续签失败，提示下载错误**

先运行 `nslookup github.com`，再确认 IPA URL 可在无登录状态下直接下载。也检查 `/tmp` 是否至少保留约 250 MB 空间。

**自动续签失败，提示 Apple ID 无效**

Apple 会话可能过期或需要再次完成双重验证。打开管理页面重新登录后，下一次刷新会继续使用新会话。

**路由器重启后还能续签吗？**

可以。开机服务会恢复 `atvloadly`，配对信息、账户会话和远程 IPA URL 都保存在 `/opt/atvloadly/data`；IPA 本身不保存，任务运行时会重新下载。

## 致谢

本项目基于 [bitxeno/atvloadly](https://github.com/bitxeno/atvloadly) 和 [bitxeno/PlumeImpactor](https://github.com/bitxeno/PlumeImpactor) 构建。
