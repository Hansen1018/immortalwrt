<img src="https://avatars.githubusercontent.com/u/53193414?s=200&v=4" alt="logo" width="200" height="200" align="right">

# ImmortalWrt + Honk

An [ImmortalWrt](https://github.com/immortalwrt/immortalwrt) tree with three upstream projects
built in, so the images need no extra feed:

- **honk** - an eBPF transparent proxy core (dae compatible), in Rust, shipped as a prebuilt core
- **doona** - honk's web panel, packaged as a LuCI app
- **Vantage** - a LuCI theme with a live, read-only dashboard

The tree also builds a **BTF kernel by default** on every target that can run honk: honk is a
CO-RE eBPF program and needs `/sys/kernel/btf/vmlinux` at runtime, so a kernel without BTF
would not be able to load it.

## What is in the tree

| Package | What it is | Upstream project |
|---|---|---|
| `package/honk` | the transparent proxy core, its init script and the control, maintenance and job scripts | [daeuniverse/honk](https://github.com/daeuniverse/honk) - GPL-3.0-only |
| `package/luci-app-honk` | the doona panel as a LuCI app | [Zakkaus/doona](https://github.com/Zakkaus/doona) - GPL-3.0-only |
| `package/luci-theme-vantage` | the Vantage LuCI theme | [anothaDev/luci-theme-vantage](https://github.com/anothaDev/luci-theme-vantage) - GPL-3.0-or-later |
| `package/luci-app-vantage` | the Vantage dashboard, the landing page after the login | the same upstream project |
| `package/vmlinux-btf` | a detached kernel BTF, a fallback for kernels built without `CONFIG_DEBUG_INFO_BTF` | [kenzok8/small-package](https://github.com/kenzok8/small-package) |

`honk` and `luci-app-honk` are also part of the default package list of the
`friendlyarm_nanopi-r5s` profile, so they are selected as soon as that device is chosen.

## Documentation

**[HONK.md](HONK.md)** has the full documentation: which devices can run it, the kernel BTF
requirement, the version policy, building it, the panel and the storage mode, the geodata, the
cgroup row of the panel, and the Vantage theme and dashboard.

## Build it yourself

The build needs a GNU/Linux, BSD or macOS system (a case sensitive filesystem is required) and
the usual OpenWrt dependencies. On Debian or Ubuntu:

```bash
sudo apt install -y ack antlr3 autoconf automake binutils bison build-essential bzip2   ccache clang cmake cpio flex gawk gettext git gnupg gperf haveged libelf-dev   libgmp3-dev libssl-dev llvm make ninja-build patch perl python3 python3-distutils   python3-setuptools rsync scons subversion swig texinfo unzip zlib1g-dev zstd
```

Then:

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
`CONFIG_PACKAGE_luci-app-honk=y` and `CONFIG_KERNEL_DEBUG_INFO_BTF=y`; append it to your own
`.config` for any device that can run honk.

## Firmware images

`.github/workflows/build-honk-doona.yml` builds the images on every push to this branch and
attaches them to the run. It can also be started by hand from the *Actions* tab, where the
target, the subtarget and the device are **drop-downs** rather than free text.

## Download

The upstream ImmortalWrt images and the firmware selector are unchanged by this tree:

- [ImmortalWrt Firmware Selector](https://firmware-selector.immortalwrt.org/)

If your device is supported, please follow the **Info** link to see install instructions or
consult the support resources listed below.

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

## License

ImmortalWrt is licensed under [GPL-2.0-only](https://spdx.org/licenses/GPL-2.0-only.html). The
packages this tree adds carry their own licenses: honk and doona are GPL-3.0-only, the Vantage
theme GPL-3.0-or-later. The full texts are in each package's `LICENSE` file.

## Acknowledgements
<table>
  <tr>
    <td><a href="https://dlercloud.com/"><img src="https://user-images.githubusercontent.com/22235437/111103249-f9ec6e00-8588-11eb-9bfc-67cc55574555.png" width="183" height="52" border="0" alt="Dler Cloud"></a></td>
    <td><a href="https://www.jetbrains.com/"><img src="https://resources.jetbrains.com/storage/products/company/brand/logos/jb_square.png" width="120" height="120" border="0" alt="JetBrains Black Box Logo logo"></a></td>
    <td><a href="https://sourceforge.net/"><img src="https://sourceforge.net/sflogo.php?type=17&group_id=3663829" alt="SourceForge" width=200></a></td>
  </tr>
</table>
