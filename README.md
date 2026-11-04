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
| `honk` | eBPF transparent proxy core (dae-compatible), Rust, ships a prebuilt aarch64 binary | [daeuniverse/honk](https://github.com/daeuniverse/honk) — GPL-3.0-only |
| `luci-app-honk` | "doona", the static web UI of honk, packaged as a LuCI app | [Zakkaus/doona](https://github.com/Zakkaus/doona) — GPL-3.0-only |
| `vmlinux-btf` | optional *detached* kernel BTF, a fallback for kernels built without `CONFIG_DEBUG_INFO_BTF` | `kenzok8/small-package` |

The packaging is vendored from `kenzok8/small-package`. Note that `kenzok8/small-package`
never committed `honk/files/update.sh` even though its Makefile installs it and the runtime
needs it (`/usr/share/honk/update.sh` is called by `job.sh` and by `usr/libexec/rpcd/honk`);
the file was restored from the complete `kenzok8/small` repository here.

### The kernel must ship BTF

`honk` is a CO-RE eBPF program, so at runtime it requires `/sys/kernel/btf/vmlinux`. That
file only exists when the kernel itself is compiled with `CONFIG_DEBUG_INFO_BTF=y` — a
detached BTF (`/usr/lib/debug/boot/vmlinux-*`, provided by the `vmlinux-btf` package) does
**not** satisfy that check.

Upstream only builds a BTF kernel for the buildbot:

```
default y if (TARGET_armsr || ... || TARGET_rockchip || ...) && BUILDBOT
```

This branch changes `config/Config-kernel.in` so that **rockchip always builds a BTF kernel**
(`&& (BUILDBOT || TARGET_rockchip)`), and keeps full debug info for it
(`CONFIG_DEBUG_INFO_REDUCED` is off for rockchip) because `DEBUG_INFO_BTF` depends on
`!DEBUG_INFO_REDUCED`.

The `pahole` tool comes from the tree itself (`tools/dwarves`, pulled in by
`select DWARVES`), so no extra host package has to be installed.

Side effects of the change:

* the kernel image grows by about 4 MB (the `.BTF` section),
* the kernel keeps full DWARF debug info, which makes the kernel build slower and bigger
  in the build directory (the shipped image is not affected by the DWARF part).

### Build it yourself

```bash
git clone -b master-Honk+Doona https://github.com/Hansen1018/immortalwrt.git
cd immortalwrt
./scripts/feeds update -a && ./scripts/feeds install -a

cat > .config <<'EOF'
CONFIG_TARGET_rockchip=y
CONFIG_TARGET_rockchip_armv8=y
CONFIG_TARGET_rockchip_armv8_DEVICE_friendlyarm_nanopi-r5s=y
CONFIG_PACKAGE_honk=y
CONFIG_PACKAGE_luci-app-honk=y
EOF

make defconfig
make -j$(nproc)
```

`honk` and `luci-app-honk` are part of the default package list of the
`friendlyarm_nanopi-r5s` profile (`target/linux/rockchip/image/armv8.mk`), so they are
selected automatically as soon as that device profile is chosen.

### GitHub Actions

`.github/workflows/build-honk-doona.yml` builds the same image on every push to this
branch and attaches the `*-sysupgrade.img.gz` to the run. It can also be started manually
from the *Actions* tab.

### After flashing

* the web UI is at `http://<router-ip>/cgi-bin/luci/admin/services/honk/`
* `honk` needs the bpffs mounted at `/sys/fs/bpf` (OpenWrt's `/etc/init.d/boot` does that),
  the kernel modules `sch_ingress`, `cls_bpf`, `veth`, `nft_queue` and `nfnetlink_queue`
  (installed by `kmod-sched-core`, `kmod-sched-bpf`, `kmod-veth`, `kmod-nft-queue`) and
  `ip` from `ip-full`.

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
