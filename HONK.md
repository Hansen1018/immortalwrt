# Honk + Doona (eBPF transparent proxy) 与 Vantage（LuCI 主题与仪表盘）

This branch (`honk-vantage`) integrates upstream projects directly into the tree,
so they can be built without adding any extra feed: the honk core and the doona panel
(the packages below), and the Vantage LuCI theme with its dashboard (the last section
of this file).

| Package | What it is | Upstream project |
|---|---|---|
| `honk` | eBPF transparent proxy core (dae-compatible), Rust, ships a prebuilt core | [daeuniverse/honk](https://github.com/daeuniverse/honk) — GPL-3.0-only |
| `luci-app-honk` | "doona", the static web UI of honk, packaged as a LuCI app | [Zakkaus/doona](https://github.com/Zakkaus/doona) — GPL-3.0-only |
| `vmlinux-btf` | optional *detached* kernel BTF, a fallback for kernels built without `CONFIG_DEBUG_INFO_BTF` | `kenzok8/small-package` |

The packaging is vendored from `kenzok8/small-package`. Note that `kenzok8/small-package`
never committed `honk/files/update.sh` even though its Makefile installs it and the runtime
needs it (`/usr/share/honk/update.sh` is called by `job.sh` and by `usr/libexec/rpcd/honk`);
the file was restored from the complete `kenzok8/small` repository here.

## Which devices can run it

`honk` is a CO-RE eBPF program, so it needs a kernel with BTF, and the prebuilt cores exist
for three architectures only:

| Architecture | Prebuilt core | Subtargets in this tree |
|---|---|---|
| x86_64 | `honk-core-…-x86_64` | `x86/64` |
| aarch64 | `honk-core-…-aarch64` | `airoha/an7581`, `airoha/an7583`, `bcm27xx/bcm2710`, `bcm27xx/bcm2711`, `bcm27xx/bcm2712`, `bcm4908/generic`, `imx/cortexa53`, `layerscape/armv8_64b`, `mediatek/filogic`, `mediatek/mt7622`, `microchipsw/lan969x`, `mvebu/cortexa53`, `mvebu/cortexa72`, `qualcommax/ipq807x`, `qualcommax/ipq60xx`, `qualcommax/ipq50xx`, `qualcommbe/ipq95xx`, `rockchip/armv8`, `sunxi/cortexa53` |
| armv7-A | `honk-core-…-armv7` | `airoha/en7523`, `at91/sama7`, `bcm27xx/bcm2709`, `bcm53xx/generic`, `imx/cortexa7`, `imx/cortexa9`, `ipq40xx/generic`, `ipq40xx/chromium`, `ipq40xx/mikrotik`, `ipq806x/generic`, `ipq806x/chromium`, `layerscape/armv7`, `mediatek/mt7623`, `mediatek/mt7629`, `mvebu/cortexa9`, `mxs/generic`, `omap/generic`, `rockchip/armv7`, `stm32/stm32mp1`, `sunxi/cortexa8`, `sunxi/cortexa7`, `zynq/generic` |

That is 42 subtargets and 888 device profiles. `honk` is only *offered* on those subtargets —
`package/honk/Makefile` names them in its `DEPENDS` — and on the 32-bit ARM ones the build
stops with a clear message if the CPU turns out to be older than ARMv7-A.

## The kernel must ship BTF

`honk` needs `/sys/kernel/btf/vmlinux` at runtime, and that file only exists when the
kernel itself is compiled with `CONFIG_DEBUG_INFO_BTF=y`. A detached BTF
(`/usr/lib/debug/boot/vmlinux-*`, provided by the `vmlinux-btf` package) does **not**
satisfy that check.

Upstream only builds a BTF kernel for the buildbot:

```
default y if (TARGET_armsr || ... || TARGET_rockchip || ...) && BUILDBOT
```

This branch changes `config/Config-kernel.in` so that **every target that can run honk
builds a BTF kernel by default**, and keeps the full debug info for it
(`CONFIG_DEBUG_INFO_REDUCED` is off there) because `DEBUG_INFO_BTF` depends on
`!DEBUG_INFO_REDUCED`.

`pahole` comes from the tree itself (`tools/dwarves`, pulled in by `select DWARVES`), so no
extra host package has to be installed.

Side effects of the change:

* the kernel image grows by about 4 MB (the `.BTF` section),
* the kernel keeps full DWARF debug info, which makes the kernel build slower and bigger
  in the build directory (the shipped image is not affected by the DWARF part).

## 版本号跟着上游走

包的版本号与上游 [kenzok8/openwrt-honk](https://github.com/kenzok8/openwrt-honk) 的发布
保持一致，**两个包各跟各的版本号**：上游每份发布都带一份 `release-manifest.json`，
里面的 `honk_version` 与 `luci_version` 是分开的 —— 哪个包的内容变了，就只给它升
版本，另一个不动。现在这里是 `honk` `2026.11.12-r1`（核心归档没变，上游升了版本）与
`luci-app-honk` `2026.11.12.2-r1`（面板归档也没变，上游把它升到了 .2），与上游
那份清单逐字一致。这样从上游软件源切换过来
时 apk 看到的是同版本，不会出现「降级」或 world 冲突；我们的改动（面板管理员、
地理数据、存储模式同步等）随上游的每次发布一起重新发布。

版本号说的是「对应上游的哪一次发布」，包里装的是什么由 provenance 记着：上游的
`v2026.11.12.2` 是用它当时的 pin 编译的，这里的同名包带的是更新（也更经得起验证）
的核心与面板。同一个版本号下内容不同，apk 分不出来 —— 所以别把上游的同名包和这里
的包混着装。

## Build it yourself

```bash
git clone -b honk-vantage https://github.com/Hansen1018/immortalwrt-honk.git
cd immortalwrt-honk
./scripts/feeds update -a && ./scripts/feeds install -a

# the target and the device, e.g. the FriendlyARM NanoPi R5S
cat > .config <<'EOF'
CONFIG_TARGET_rockchip=y
CONFIG_TARGET_rockchip_armv8=y
CONFIG_TARGET_rockchip_armv8_DEVICE_friendlyarm_nanopi-r5s=y
EOF

# plus honk + doona and a BTF kernel
cat config/honk-doona.config >> .config

make defconfig
make -j$(nproc)
```

`config/honk-doona.config` is a ready-made seed with `CONFIG_PACKAGE_honk=y`,
`CONFIG_PACKAGE_luci-app-honk=y` and `CONFIG_KERNEL_DEBUG_INFO_BTF=y`; append it to your
own `.config` for any device from the table above.

`honk` and `luci-app-honk` are also part of the default package list of the
`friendlyarm_nanopi-r5s` profile (`target/linux/rockchip/image/armv8.mk`), so they are
selected automatically as soon as that device profile is chosen.

## GitHub Actions

`.github/workflows/build-honk-doona.yml` builds the image on every push to this branch and
attaches it to the run. It can also be started manually from the *Actions* tab, where the
target, the subtarget and the device are **drop-downs**, not free text:

| Input | Options | Meaning |
|---|---|---|
| `target` | 22 | the OpenWrt target (`rockchip`, `x86`, `qualcommax`, ...) |
| `subtarget` | 43 | given as `target/subtarget` (`rockchip/armv8`, `x86/64`, ...) |
| `device` | 780 | the device profile (`friendlyarm_nanopi-r5s`, `generic`, ...) |

The lists are generated from the tree, so a new device profile appears in the dialog
automatically. To refresh them after a tree update:

```bash
make defconfig
python3 scripts/gen-honk-workflow-options.py
```

The workflow checks that the target matches the subtarget and that the device belongs to
it, and prints the valid devices of that subtarget when it does not.

## After flashing

* the web UI is at `http://<router-ip>/cgi-bin/luci/admin/services/honk/`
* `honk` needs the bpffs mounted at `/sys/fs/bpf` (OpenWrt's `/etc/init.d/boot` does that),
  the kernel modules `sch_ingress`, `cls_bpf`, `veth`, `nft_queue` and `nfnetlink_queue`
  (installed by `kmod-sched-core`, `kmod-sched-bpf`, `kmod-veth`, `kmod-nft-queue`) and
  `ip` from `ip-full`.

## 存储模式：导入与修订历史

honk 有两种配置存储模式，由 UCI 选项 `honk.main.store` 决定（默认 `db`）：

| 模式 | 核心启动参数 | 导入 | 修订历史 |
|---|---|---|---|
| `db`（默认） | `honk-core --config /etc/honk/config.dae --store db --data-dir /etc/honk` | 可用 `/api/v1/x-honk/config/import` | 可用 `/api/v1/x-honk/config/revisions` |
| `file` | `honk-core --config /etc/honk/config.dae --data-dir /etc/honk` | 路由返回 `404 capability_not_supported` | 同样返回 404 |

**Doona 面板里的「导入」和「配置修订历史」只在 `db` 模式下存在** —— 文件模式下这两个
路由由核心直接回 404，界面不会显示它们。

`db` 模式的前提（核心会 fail-closed 检查，缺一即拒绝启动）：

- `experimental.native_api.enabled: true`
- `experimental.native_api.config_write: true`
- 一个管理员凭据（面板的首次初始化会通过 `/api/v1/auth/setup` 建立）
- **`--data-dir` 必须与配置里的 `global.data_dir` 完全一致**（这里是 `/etc/honk`）。
  核心会直接比较这两个值，不一致就退出：
  `global.data_dir /etc/honk differs from --data-dir /var/lib/honk`。
  `honk.init` 因此会从配置里读出 `data_dir` 再传给核心；`control.sh`、`maintenance.sh`
  里的 mock 核心也传同一个值 —— Doona 管理员口令存在 `<data_dir>/state/honk.db`，
  两边不一致的话 mock 建好的账号真实核心看不到（面板会一直提示先初始化）。

`db` 模式下的两点变化：

- `/etc/honk/config.dae` 变成**导入用的源树**（导入时会重新读取它），运行中的配置由核心
  托管在自己的状态库（`state/honk.db`）里，每次改动都记为一个修订。LuCI 面板里直接改
  文件的动作不再生效，改配置请用 Doona 面板（`http://<路由器IP>:9527/`）。
- 核心在 `db` 模式下**不运行 Clash API**（此时设置 `experimental.clash_api.external_controller`
  会得到提示），需要 Clash API 请改回 `file` 模式。

回到文件模式（honk 官方的步骤）：

```sh
honk-core config export --out /etc/honk/config.dae --data-dir /etc/honk
uci set honk.main.store='file'
uci commit honk
service honk restart
```

（`config export` 与 `admin reset` 同样受 `--data-dir` 约束，漏掉会报
`global.data_dir ... differs from --data-dir ...`。）

## 存储模式（db）与修订历史

核心有两种存储模式，由 UCI 的 `honk.main.store` 决定（默认 `db`）：

- **切换方式**：LuCI 的「Honk → 设置 → 存储模式」（选「数据库（修订历史）」或「配置文件」，
  保存后自动重启服务）；或者命令行 `uci set honk.main.store=db && uci commit honk &&
  /etc/init.d/honk restart`。
- `/etc/config/honk` 是 conffile，升级固件时会保留旧文件，里面可能没有 `store` 这个键
  （这个键是后来才加的）。缺省时按 `db` 处理，首次启动的迁移脚本也会把它补写进去。
  概览页的「存储模式」一行显示的是**实际生效**的模式（读运行中核心的命令行），
  不一致时会告警；核心跑在 file 模式时还会提示「没有导入与修订历史」。

- `file`：以 `/etc/honk/config.dae` 为准。
- `db`：核心托管配置，`.dae` 源作为**修订**存在 `<data_dir>/state/honk.db` 里。

只有 `db` 模式才提供配置导入与修订历史（file 模式下核心报告
`config_import.available=false`，面板里的导入与修订历史就是灰的）。所以 `honk.init`
会按 UCI 的设置传 `--store db --data-dir <global.data_dir>`（两者必须完全一致，
否则核心直接退出）。状态页会同时显示**配置的**与**实际生效的**存储模式——两者不一致
时会有告警。

**`db` 模式下配置文件不再是配置的来源**：上游的规矩是「有修订在库里时，启动跑的是
库里的活动修订，不再读 `-c`」，「文件改动只有经过 `import`（`replace:true`）才进库」。
也就是说 `db` 模式里配置归**面板**管（面板的导入与修订历史就是干这个的），LuCI 写进
`/etc/honk/config.dae` 的东西不会自己生效；`file` 模式里反过来，配置文件说了算，
面板的导入与修订历史用不了。两种模式可以随时切换（设置页的「存储模式」），切回
`file` 的官方做法是先 `honk-core config export --out /etc/honk/config.dae` 把库里的
内容导成文件。


## 升级固件后面板要求「新建管理员」，LuCI 却一切正常

面板（Doona）问的是**核心**：`GET /api` 里的 `auth.setup_required` 为真时，它就显示
「新建管理员」；LuCI 以前只看 UCI 里的 `honk.main.initialized`（升级固件时这个标记
是保留的），所以两边说法不一致。

管理员记录在核心的状态库里：`<data_dir>/state/honk.db` 的 `admin` 表。**这个库是
SQLite 的 WAL 模式**：建管理员时记录先写进 `honk.db-wal`，要等 checkpoint 才进
`honk.db` 本身。核心退出时不做 checkpoint（实测：SIGTERM 正常退出后 `-wal` 还在，
记录也就只活在那一份 WAL 里）。于是只要 `-wal` 丢了——固件升级动了状态目录、掉电、
清理临时文件——管理员记录就没了，而 `/etc/config/honk` 的 `initialized=1` 还在：
**面板要新建管理员，LuCI 看着一切正常。**

包里的对策：

- **落盘**：`maintenance.sh checkpoint` 做 `PRAGMA wal_checkpoint(TRUNCATE)` 并清掉
  残留的 `-wal/-shm`。建完管理员（`control.sh initialize`）、停服务（`honk.init` 的
  `stop_service`）、重置管理员时都会落一次盘，管理员记录从此在 `honk.db` 本身里，
  `-wal` 丢了也不怕。
- **说实话**：状态接口多了一个 `admin_setup_required`（直接问核心的 `/api`）。管理员
  记录没了时，概览页会给出「面板要求新建管理员」的告警**和建账号的表单**，跟面板
  做同一件事，LuCI 不再装作什么都不知道。
- **能补救**：`initialize` 允许在 `initialized=1` 时重来（管理员还在的话走的是登录
  分支，不会覆盖已有账号），LuCI 的表单就是走这条路。

**为什么 LuCI 页面有时看不到新控件**：LuCI 的静态资源缓存键是 LuCI 自己的版本号
（`luci.js` 的 `?v=`），**不含本包的版本**，所以升级 luci-app-honk 之后浏览器往往
还在用旧的 JS。升级后**强制刷新一次页面**（Ctrl+F5，或清理浏览器缓存）即可；
不想刷新就用上面的命令行入口。

## 地理数据：文件在哪、源在哪、为什么以前更新不了

**文件放在数据目录里**（`/etc/honk/geosite.dat`、`/etc/honk/geoip.dat`），不是软件包
装的那份。软件包（v2ray-geodata）把文件放在只读分区（squashfs）里，核心更新时要
**原地替换**加载着的那份 —— 写不进去，面板的「立即更新」就停在替换阶段
（`replacement_failed`），文件其实一个字节都没换。数据目录可写又是持久的，所以：

- `control.sh geodata-files` 在**每次启动**时把软件包的那份**复制**到数据目录（24MB）：缺了、
  是**符号链接**、或者是 0 字节的**空壳**，都换成真的那份。符号链接旁边核心拒绝落盘
  （实测报的是 `replacement_failed`，面板的更新必然失败），空壳读不出分类（核心当没有
  这份资产，`can_update` 直接为假，面板的「立即更新」被拒）—— 而 LuCI 那条路写临时文件
  再 mv，绕开了这两件事，所以它看着一直是好的；
- 之前只在初始化时复制一次：已经初始化过的设备上从来没有那两份文件，资产目录就一直退回
  到只读的那份 —— 面板的「立即更新」于是停在替换阶段（`written: false`、
  `durability_confirmed: false`），而 LuCI 那条路直接写数据目录，所以它看着是好的；
- 复制之后核心更新时就地替换数据目录里那份；
- `apk` 升级 `honk` 包时会重启一次服务（包的 postinst）：apk 自己不会重启服务，核心还
  拿着旧的资产目录与旧的下载源清单，面板的「立即更新」于是还是停在替换阶段 —— 刷固件
  本来就会重启，只有 apk 这条路需要包自己来做；
- 复制不了（overlay 空间不够）就退回软件包那份：核心照常能起，只是更新仍替换不了；下次
  启动会再试一次；
- `DAE_LOCATION_ASSET` 指向数据目录，核心因此在数据目录里找、在数据目录里替换。

**源是四个地址，一个不通就换下一个**：上游原版的两个在前（MetaCubeX 的
`meta-rules-dat`：`raw.githubusercontent`，然后是 GitHub 慢的时候走的 `jsDelivr`），
我们自己那份 `Loyalsoldier/v2ray-rules-dat` 在后当兜底（同样是 raw + jsDelivr）。
每个文件四个地址，核心按顺序一个一个试 —— 配置文件里写死一个地址就没有这个退路
（面板的「立即更新」当初就是这么坏的），所以 `assets` 里不写 geodata 段。校验和按
上游的规则取 `<地址>.sha256sum`（404 就算没校验过，其它错误直接拒绝这次尝试）。

这四个地址写在**状态库**里（`control.sh geodata-sources`，核心启动时读进去），不在
配置文件里：核心的配置文件每个文件只能写一个下载地址，库里可以存最多四个。用户在
LuCI 里填了自己的地址（`honk.main.<type>_url`）就用那一个，核心那边也一样；用户在
面板里自己设的列表不动。LuCI 的 `update-geo.sh` 用同一份列表、同一个顺序，两条路径
拿到的字节相同，就不会再互相覆盖。

**运行时生成的 system.dae 同样不写这一段**（面板接管、修复、恢复都会重新生成这个
文件）。以前生成的那份写死了一个 GitHub 地址并强制直连：地址只有一个，墙内不通就
只剩一次机会，面板的「立即更新」于是停在下载阶段（下载超时）；`route: direct` 还
绕过了路由规则，出口不由用户决定。现在生成的和随包发的那份一致：核心用内置的列表，
路由规则决定出口。

**设备上已有的旧文件会被迁移**：`/etc/honk/system.dae` 是 conffile，升级时保留设备
上那份，于是旧版本写死的那段还在。服务启动时 `control.sh migrate` 把它去掉（只认我们
自己写的那份：写的是别的地址就当用户自己的配置，不动），换掉之后整个配置重新校验，
不合法就换回原来那份。改了文件就清掉状态库里的修订，让核心按当前文件重新导入 ——
db 模式下核心跑的是库里的修订，文件改了不重新导入就不生效。

**库里那份下载源是启动时算一次的**：核心在 `Sources::open` 里按**当前运行的配置**算一次
下载源清单（`seed`），之后一直用它 —— 换句话说，「更新」要等下次启动才生效。db 模式下
核心跑的是状态库里的修订：修订还是旧的时候，库里记着的仍是那个写死的地址，面板的
「立即更新」就只会超时。

`control.sh sync-db` 会发现这种过时状态（库里记着的、来自旧配置文件的地址，当前配置
文件里已经没有了），把核心自己的几张表清掉 —— `head`、`revision`、`listener_secret`：
管理员记录、订阅记录在别的表里，不受影响。核心下次启动就按上游的规矩（「库里没有修订
时，启动会导入 `-c`」）把当前配置文件导入成修订 1，下载源回到内置列表。

`listener_secret` 必须一起清：启动导入会把**文件里**的密钥重新插进这张表，旧行还在就撞
唯一索引，导入失败，核心报 `configuration db: configuration database is unavailable`
直接退出。只在库里、文件里没有的密钥保留 —— 核心不会重插那一条，留着不冲突。核心在跑的
时候不动它的库（清完 `head` 之后核心手里的 head 指着一条不存在的修订），等下次启动再说。

**下载走哪条路由由路由规则决定**（和上游一样，`assets` 里不写 geodata 段，核心按
规则选出口；写 `route: direct` 才是强制直连）。规则最终落到哪个出口，下载就走哪个
出口 —— 想让地理数据下载走代理，改路由规则就行。

**下载要一个能用的解析器**：直连下载主机名 URL 只走 `global.bootstrap_resolver`，
没有系统解析器回退。这里用路由器自己的 `127.0.0.1:53`（dnsmasq），它永远可达，
答案与系统解析器一致。

## 面板与 LuCI 的两条地理数据路径

面板里的「立即更新」走核心自带的 API（`POST /api/v1/geodata/update`），LuCI 里的「更新」
走 `update-geo.sh`。两者下载**同一个源**、装到**同一个目录**（数据目录），拿到的字节
相同，核心会判定「内容一致」而不重复覆盖，**两边不会互相干扰**。

源是上面那四个地址（上游原版两个在前，我们那份 Loyalsoldier 在后兜底）：配置里不写
下载源，列表写在状态库里，LuCI 脚本用同一份地址、同一个顺序（一个不通就换下一个）。
用户在设置页填了自己的 URL 时，核心按配置优先，LuCI 脚本也优先用它。

源必须是「文件与 `.sha256sum` 自洽」的镜像：校验和对不上时核心会拒绝替换并沿用当前
文件，面板报的是「新的地理数据文件未通过校验：文件无法解析，或缺少规则使用的分类」。
校验和按上游的规则取 `<地址>.sha256sum`（404 算没校验过，其它错误直接拒绝这次尝试）。

**这里必须用本机解析器，不能换公网上的 DNS。** 订阅的 `route: direct` 抓取同样走这个
resolver，而且它一旦解析出结果就不再回落到系统解析器（只有失败或空结果才回落）。换成
公网 DNS 等于替所有订阅换了 DNS：被污染或劫持的域名会解析到错的地址，订阅就再也拉
不到数据。实测（真实核心 + 假 resolver）：配了它之后订阅 `status=stale`、节点为 0、
日志是 `Subscription fetch deadline reached`；去掉它同一个订阅立刻正常。

LuCI 侧在装进文件系统之前做两道检查：先比对发布的 `.sha256sum`，再让**核心**用候选文件
编译一遍当前配置 —— 只有核心能判断「文件能不能解析、规则用到的分类齐不齐」。

## 面板的 cgroup 一栏：为什么以前是空的

面板概览里的「cgroup 已用 / cgroup 上限 / cgroup 范围」来自核心的遥测：核心读**自己所在
那个 cgroup** 的 `memory.current`、`memory.max`、`memory.events`。这三个文件只有在内核把
`memory` 控制器**委派到那个 cgroup** 时才存在，而 OpenWrt 自己不委派任何控制器（整机
没有任何地方在启动时写过 `cgroup.subtree_control`；只有 procd 创建容器时才会写）。于是
核心读不到，读不到就没有 `cgroup` 这个能力项（能力接口里没有 `cgroup.current_bytes`），
面板就把这一栏藏了起来。

包里补上了这一步（`honk.init` 的 `honk_cgroup_delegate_memory`，服务启动前跑一次）：

- 委派的链条是 `根 -> services -> services/honk -> services/honk/main`。procd 把每个服务
  实例放在 `/sys/fs/cgroup/services/<服务>/<实例>`，honk 的实例名是 `main`；
- **实例 cgroup 由包先建好**：procd 要等实例起来才建，那时已经来不及委派了；
- 控制器只对 `cgroup.subtree_control` 里打开的那一级**以下**的子 cgroup 生效，所以要从
  根往下逐级写；
- 根 cgroup 不受「cgroup 里有进程就不能开控制器」的限制（内核文档
  `Documentation/admin-guide/cgroup-v2.rst`：「The root cgroup is exempt from this
  restriction」），所以即使 procd（PID 1）就在根 cgroup 里，这一步照样成立 —— 实测在有
  100 多个进程的根 cgroup 上写 `+memory` 是成功的；
- 内核没编译 `memory` 控制器、或者根本没挂 cgroup2 时，这一步什么都不做，服务照常起。

委派之后核心的遥测就有数据了：`/api/v1/runtime/memory` 里出现
`"cgroup":{"current_bytes":…,"scope":"service"}`，能力接口里出现 `cgroup.current_bytes`，
面板的 cgroup 一栏随之出现。「cgroup 范围」显示「本服务」，是因为实例 cgroup 的
`cgroup.procs` 里只有核心自己一个 pid。

## `kernel argv capture unavailable; using thread comm`

核心日志里的这行是**降级提示，不是启动失败**。

`pname(...)` 规则要匹配完整的 `argv[0]`，honk 于是让 **cgroup 程序**去读调用者任务的
`mm->arg_start`。而内核给 cgroup 程序的 helper 白名单
（`kernel/bpf/cgroup.c` 里的 `cgroup_current_func_proto`）只放行
`bpf_get_current_uid_gid`、`bpf_get_current_pid_tgid`、`bpf_get_current_comm`、
`bpf_get_cgroup_classid`、`bpf_current_task_under_cgroup`；
argv0 那条路需要的 `bpf_get_current_task`、`bpf_probe_read_kernel`、
`bpf_probe_read_user_str`、`bpf_loop` **都不在白名单里**，验证器因此直接拒绝那个程序，
honk 就退回用线程的 `comm`。

上游自己知道这件事：代码注释写着「有些内核全局认识这些 helper，却拒绝 cgroup 程序使用」，
路由参考文档也把 `comm` 回落写成了既定行为 ——「当运行期 BTF 偏移量或内核可安全提供的
argv 访问不可得时，cgroup 钩子改用调用线程的 `comm`」。

实际影响：

- `pname(...)` 规则**照常工作**，只是匹配对象从 `argv[0]` 的 basename 变成 15 字节的线程名
  （只有名字超过 15 字节、或进程自己改过名时才有差别）；
- 转发、DNS、订阅以及其它功能都不受影响。

包层面无法关掉它：探测逻辑在预编译核心自带的 eBPF 对象里，而内核的 helper 白名单不是包能改的。
要拿到真正的 `argv[0]`，需要上游改动（cgroup 程序里只取 pid、`argv[0]` 交给用户态解析，
或者把读取挪到白名单允许的程序类型里），并配套重编 eBPF 对象。

包能保证的是这个条件的另一半：**BTF 侧是齐的** —— 我们的内核带完整 BTF，
`task_struct.mm` 与 `mm_struct.arg_start` 都能解析出来，honk 的 `process_name::detect`
拿得到偏移量。

## Vantage：LuCI 主题与仪表盘

固件里集成了 [Vantage](https://github.com/anothaDev/luci-theme-vantage)（作者 anothaDev，
GPL-3.0-or-later）：一套 LuCI 主题（图标栏、面包屑、Ctrl+K 搜索、明暗主题、手机端底栏）
和一个只读的实时仪表盘（上线状态、CPU/内存/无线/客户端、实时流量、防火墙概览）。

两个包**原样**放在 `package/` 里（上游 v1.0.20，commit `0f8d16f2ce25`，文件与上游逐字节
一致）：

| 包 | 作用 |
|---|---|
| `package/luci-theme-vantage` | 主题本身（`/www/luci-static/vantage`） |
| `package/luci-app-vantage` | 仪表盘（登录后的首页 `admin/dashboard`） |

用「放进树里」而不是加 feed：`feeds.conf` 与 `.config` 都不进 git，feed 的写法在这个
分支里留不下来；放进 `package/` 才能随分支一起走，编译时也不必再联网取一次。

**默认就是它。** 主题包自带 `/etc/uci-defaults/30_luci-theme-vantage`：首次启动时把
`luci.themes.Vantage` 注册进 LuCI，并在它是新条目时把 `luci.main.mediaurlbase` 指到
`/luci-static/vantage`。`/etc/uci-defaults/` 按文件名排序执行，`30_luci-theme-bootstrap`
排在 `30_luci-theme-vantage` 前面（先把自己设成 bootstrap），主题包的脚本随后无条件
改写 ⇒ **最后落在 Vantage 上**。升级固件后这脚本同样跑一次，所以老设备刷完新固件直接
就是新主题；也可以在「系统 → 语言和风格 → 主题」里手动切。

简体中文翻译一起编进来：`luci-i18n-vantage-theme-zh-cn`（主题）与
`luci-i18n-vantage-zh-cn`（仪表盘）。

**更新到上游新版本**（把下面的 `v1.0.20` 换成目标版本）：

```sh
git clone --depth 1 --branch v1.0.20 https://github.com/anothaDev/luci-theme-vantage.git /tmp/vantage
rm -rf package/luci-theme-vantage package/luci-app-vantage
cp -a /tmp/vantage/luci-theme-vantage /tmp/vantage/luci-app-vantage package/
chown -R openwrt:openwrt package/luci-theme-vantage package/luci-app-vantage
```

**不想要它**：把 `.config` 里的 `CONFIG_PACKAGE_luci-theme-vantage` 与
`CONFIG_PACKAGE_luci-app-vantage` 去掉（`make defconfig` 后再编译）即可；主题包的
`postrm` 会把 LuCI 切回别的已注册主题，不会留下一指向不存在主题的配置。
