<img src="https://avatars.githubusercontent.com/u/53193414?s=200&v=4" alt="logo" width="200" height="200" align="right">

# Project ImmortalWrt

ImmortalWrt is a fork of [OpenWrt](https://openwrt.org), with more packages ported, more devices supported, default optimized profiles and localization modifications for mainland China users.<br/>
Compared to upstream, we allow to use (non-upstreamable) modifications/hacks to provide better feature/performance/support.

Default login address: http://192.168.1.1 or http://immortalwrt.lan, username: __root__, password: _none_.

## Download
Built firmware images are available for many architectures and come with a package selection to be used as WiFi home router. To quickly find a factory image usable to migrate from a vendor stock firmware to ImmortalWrt, try the *Firmware Selector*.

- [ImmortalWrt Firmware Selector](https://firmware-selector.immortalwrt.org/)

If your device is supported, please follow the **Info** link to see install instructions or consult the support resources listed below.

## Development
To build your own firmware you need a GNU/Linux, BSD or macOS system (case sensitive filesystem required). Cygwin is unsupported because of the lack of a case sensitive file system.<br/>

  ### Requirements
  To build with this project, Debian 11 is preferred. And you need use the CPU based on AMD64 architecture, with at least 4GB RAM and 25 GB available disk space. Make sure the __Internet__ is accessible.

  The following tools are needed to compile ImmortalWrt, the package names vary between distributions.

  - Here is an example for Debian/Ubuntu users:<br/>
    - Method 1:
      <details>
        <summary>Setup dependencies via APT</summary>

        ```bash
        sudo apt update -y
        sudo apt full-upgrade -y
        sudo apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
          bzip2 ccache clang cmake cpio curl device-tree-compiler ecj fastjar flex gawk gettext gcc-multilib \
          g++-multilib git gnutls-dev gperf haveged help2man intltool lib32gcc-s1 libc6-dev-i386 libelf-dev \
          libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses-dev libpython3-dev \
          libreadline-dev libssl-dev libtool libyaml-dev libz-dev lld llvm lrzsz mkisofs msmtp nano \
          ninja-build p7zip p7zip-full patch pkgconf python3 python3-pip python3-ply python3-docutils \
          python3-pyelftools qemu-utils re2c rsync scons squashfs-tools subversion swig texinfo uglifyjs \
          upx-ucl unzip vim wget xmlto xxd zlib1g-dev zstd
        ```
      </details>
    - Method 2:
      ```bash
      sudo bash -c 'bash <(curl -s https://build-scripts.immortalwrt.org/init_build_environment.sh)'
      ```

  Note:
  - Do everything as an unprivileged user, not root, without sudo.
  - Using CPUs based on other architectures should be fine to compile ImmortalWrt, but more hacks are needed - No warranty at all.
  - You must __not__ have spaces or non-ascii characters in PATH or in the work folders on the drive.
  - If you're using Windows Subsystem for Linux (or WSL), removing Windows folders from PATH is required, please see [Build system setup WSL](https://openwrt.org/docs/guide-developer/build-system/wsl) documentation.
  - Using macOS as the host build OS is __not__ recommended. No warranty at all. You can get tips from [Build system setup macOS](https://openwrt.org/docs/guide-developer/build-system/buildroot.exigence.macosx) documentation.
  - For more details, please see [Build system setup](https://openwrt.org/docs/guide-developer/build-system/install-buildsystem) documentation.

  ### Quickstart
  1. Run `git clone -b <branch> --single-branch --filter=blob:none https://github.com/immortalwrt/immortalwrt` to clone the source code.
  2. Run `cd immortalwrt` to enter source directory.
  3. Run `./scripts/feeds update -a` to obtain all the latest package definitions defined in feeds.conf / feeds.conf.default
  4. Run `./scripts/feeds install -a` to install symlinks for all obtained packages into package/feeds/
  5. Run `make menuconfig` to select your preferred configuration for the toolchain, target system & firmware packages.
  6. Run `make` to build your firmware. This will download all sources, build the cross-compile toolchain and then cross-compile the GNU/Linux kernel & all chosen applications for your target system.

  ### Related Repositories
  The main repository uses multiple sub-repositories to manage packages of different categories. All packages are installed via the OpenWrt package manager called opkg. If you're looking to develop the web interface or port packages to ImmortalWrt, please find the fitting repository below.
  - [LuCI Web Interface](https://github.com/immortalwrt/luci): Modern and modular interface to control the device via a web browser.
  - [ImmortalWrt Packages](https://github.com/immortalwrt/packages): Community repository of ported packages.
  - [OpenWrt Routing](https://github.com/openwrt/routing): Packages specifically focused on (mesh) routing.
  - [OpenWrt Video](https://github.com/openwrt/video): Packages specifically focused on display servers and clients (Xorg and Wayland).

## Support Information
For a list of supported devices see the [OpenWrt Hardware Database](https://openwrt.org/supported_devices)
  ### Documentation
  - [Quick Start Guide](https://openwrt.org/docs/guide-quick-start/start)
  - [User Guide](https://openwrt.org/docs/guide-user/start)
  - [Developer Documentation](https://openwrt.org/docs/guide-developer/start)
  - [Technical Reference](https://openwrt.org/docs/techref/start)

  ### Support Community
  - Support Chat: group [@ctcgfw_openwrt_discuss](https://t.me/ctcgfw_openwrt_discuss) on [Telegram](https://telegram.org/).
  - Support Chat: group [#immortalwrt](https://matrix.to/#/#immortalwrt:matrix.org) on [Matrix](https://matrix.org/).

## Honk + Doona (eBPF transparent proxy)

This branch (`master-Honk+Doona`) integrates two upstream projects directly into the tree,
so they can be built without adding any extra feed:

| Package | What it is | Upstream project |
|---|---|---|
| `honk` | eBPF transparent proxy core (dae-compatible), Rust, ships a prebuilt core | [daeuniverse/honk](https://github.com/daeuniverse/honk) — GPL-3.0-only |
| `luci-app-honk` | "doona", the static web UI of honk, packaged as a LuCI app | [Zakkaus/doona](https://github.com/Zakkaus/doona) — GPL-3.0-only |
| `vmlinux-btf` | optional *detached* kernel BTF, a fallback for kernels built without `CONFIG_DEBUG_INFO_BTF` | `kenzok8/small-package` |

The packaging is vendored from `kenzok8/small-package`. Note that `kenzok8/small-package`
never committed `honk/files/update.sh` even though its Makefile installs it and the runtime
needs it (`/usr/share/honk/update.sh` is called by `job.sh` and by `usr/libexec/rpcd/honk`);
the file was restored from the complete `kenzok8/small` repository here.

### Which devices can run it

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

### The kernel must ship BTF

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

### Build it yourself

```bash
git clone -b master-Honk+Doona https://github.com/Hansen1018/immortalwrt.git
cd immortalwrt
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

### GitHub Actions

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

### After flashing

* the web UI is at `http://<router-ip>/cgi-bin/luci/admin/services/honk/`
* `honk` needs the bpffs mounted at `/sys/fs/bpf` (OpenWrt's `/etc/init.d/boot` does that),
  the kernel modules `sch_ingress`, `cls_bpf`, `veth`, `nft_queue` and `nfnetlink_queue`
  (installed by `kmod-sched-core`, `kmod-sched-bpf`, `kmod-veth`, `kmod-nft-queue`) and
  `ip` from `ip-full`.

### 存储模式：导入与修订历史

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

### `kernel argv capture unavailable; using thread comm`

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

## License
ImmortalWrt is licensed under [GPL-2.0-only](https://spdx.org/licenses/GPL-2.0-only.html).

## Acknowledgements
<table>
  <tr>
    <td><a href="https://dlercloud.com/"><img src="https://user-images.githubusercontent.com/22235437/111103249-f9ec6e00-8588-11eb-9bfc-67cc55574555.png" width="183" height="52" border="0" alt="Dler Cloud"></a></td>
    <td><a href="https://www.jetbrains.com/"><img src="https://resources.jetbrains.com/storage/products/company/brand/logos/jb_square.png" width="120" height="120" border="0" alt="JetBrains Black Box Logo logo"></a></td>
    <td><a href="https://sourceforge.net/"><img src="https://sourceforge.net/sflogo.php?type=17&group_id=3663829" alt="SourceForge" width=200></a></td>
  </tr>
</table>
