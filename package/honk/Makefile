# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2026 kenzok8

include $(TOPDIR)/rules.mk

PKG_NAME:=honk
PKG_VERSION:=2026.11.08.2
PKG_RELEASE:=1

# Pinned honk-core revision (upstream daeuniverse/honk main), cross-compiled by
# ci/build-core.sh. Every release run publishes its core archives under an
# immutable source-<run_id> tag; the tag and SHA-256 values below are the exact
# assets behind CORE_COMMIT, so a plain feed build downloads and verifies them
# without any generated file. A staged run may still override them through
# honk/generated-stage.mk, which is generated and never committed.
CORE_COMMIT:=73b1077bf9cdb639899f0447994cf8980abc0752

# Immutable source asset tag holding this pin's core archives.
HONK_SOURCE_TAG?=source-42346679491
HONK_SOURCE_URL?=https://github.com/kenzok8/openwrt-honk/releases/download/$(HONK_SOURCE_TAG)

-include $(CURDIR)/generated-stage.mk

HONK_ASSET_X86_64?=honk-core-$(CORE_COMMIT)-x86_64.tar.gz
HONK_ASSET_AARCH64?=honk-core-$(CORE_COMMIT)-aarch64.tar.gz
HONK_ASSET_ARMV7?=honk-core-$(CORE_COMMIT)-armv7.tar.gz
HONK_HASH_X86_64?=2dcf620df287c0ffbaee8c7d0cbe1bc49b747567547b1e99d35e8be1355e0860
HONK_HASH_AARCH64?=8b34bb520acfa764212a629245502fa7b7736fb1ace4de0bc8301b8141c82ea5
HONK_HASH_ARMV7?=28ff05f304f923dccf0c106fabbbae2ff9991aa439c4635ea7652876a578645a

# ARCH_PACKAGES is the package arch (e.g. arm_cortex-a7_neon-vfpv4);
# ARCH is the CPU arch (x86_64/aarch64/arm) and coincides for 64-bit.
ifeq ($(ARCH_PACKAGES),x86_64)
  HONK_ASSET:=$(HONK_ASSET_X86_64)
  HONK_HASH:=$(HONK_HASH_X86_64)
else ifeq ($(filter aarch64%,$(ARCH_PACKAGES)),$(ARCH_PACKAGES))
  HONK_ASSET:=$(HONK_ASSET_AARCH64)
  HONK_HASH:=$(HONK_HASH_AARCH64)
else ifeq ($(filter arm_%,$(ARCH_PACKAGES)),$(ARCH_PACKAGES))
  # the prebuilt armv7 core needs an ARMv7-A capable CPU
  ifneq (,$(filter arm_cortex-a4 arm_cortex-a5 arm_arm1176jzf-s arm_arm926 arm_arm926ej-s,$(ARCH_PACKAGES)))
    $(error honk: the prebuilt core needs an ARMv7-A CPU, $(ARCH_PACKAGES) is too old)
  endif
  HONK_ASSET:=$(HONK_ASSET_ARMV7)
  HONK_HASH:=$(HONK_HASH_ARMV7)
endif

PKG_LICENSE:=GPL-3.0-only
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=kenzok8

PKG_SOURCE:=$(HONK_ASSET)
PKG_SOURCE_URL?=$(HONK_SOURCE_URL)/
PKG_HASH:=$(HONK_HASH)

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

ifeq ($(HONK_CORE_LANE),linux66)
  RSTRIP:=:
endif

define Package/honk
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=Honk transparent proxy core
  URL:=https://github.com/daeuniverse/honk
  # 不直接依赖 libubox：包名带 ABI 日期戳，会锁死固件；脚本只用 jshn 提供的 jshn.sh。
  # 不绑 @KERNEL_DEBUG_INFO_BTF：固件没编 BTF 时还有 vmlinux-btf 包这条活路，
  # 绑上去会让官方 OpenWrt 直接装不了，启动时由控制脚本给出明确报错。
    DEPENDS:=@(x86_64||aarch64||TARGET_airoha_en7523||TARGET_at91_sama7||TARGET_bcm27xx_bcm2709||TARGET_bcm53xx_generic||TARGET_imx_cortexa7||TARGET_imx_cortexa9||TARGET_ipq40xx_generic||TARGET_ipq40xx_chromium||TARGET_ipq40xx_mikrotik||TARGET_ipq806x_generic||TARGET_ipq806x_chromium||TARGET_layerscape_armv7||TARGET_mediatek_mt7623||TARGET_mediatek_mt7629||TARGET_mvebu_cortexa9||TARGET_mxs_generic||TARGET_omap_generic||TARGET_rockchip_armv7||TARGET_stm32_stm32mp1||TARGET_sunxi_cortexa8||TARGET_sunxi_cortexa7||TARGET_zynq_generic) +ca-bundle +ip-full +ubus +kmod-sched-core +kmod-sched-bpf +kmod-veth +kmod-nft-queue +curl +jsonfilter +jshn +sqlite3-cli +usign +coreutils-stat +v2ray-geoip +v2ray-geosite +@KERNEL_DEBUG_INFO_BTF
endef

define Package/honk/description
  Honk is a transparent proxy core for OpenWrt (x86_64, aarch64, armv7).
endef

define Package/honk/conffiles
/etc/config/honk
/etc/honk/config.dae
/etc/honk/system.dae
/etc/honk/manual-config.dae
/etc/honk/managed-config.dae
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(TAR) -xzf $(DL_DIR)/$(PKG_SOURCE) -C $(PKG_BUILD_DIR) --strip-components=1
endef

define Build/Compile
endef

define Package/honk/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/honk-core $(1)/usr/bin/honk-core
	if [ -f $(PKG_BUILD_DIR)/core-capabilities.json ]; then \
		$(INSTALL_DIR) $(1)/usr/share/honk; \
		$(INSTALL_DATA) $(PKG_BUILD_DIR)/core-capabilities.json $(1)/usr/share/honk/core-capabilities.json; \
	fi

	$(INSTALL_DIR) $(1)/usr/share/licenses/honk
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/LICENSE $(1)/usr/share/licenses/honk/LICENSE

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/files/honk.config $(1)/etc/config/honk

	$(INSTALL_DIR) $(1)/etc/honk
	$(INSTALL_CONF) $(CURDIR)/files/config.dae $(1)/etc/honk/config.dae
	$(INSTALL_CONF) $(CURDIR)/files/system.dae $(1)/etc/honk/system.dae
	chmod 0600 $(1)/etc/honk/system.dae
	$(INSTALL_DIR) $(1)/etc/honk/state
	chmod 0700 $(1)/etc/honk/state

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/honk.init $(1)/etc/init.d/honk
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(CURDIR)/files/90-honk-boot $(1)/etc/uci-defaults/90-honk

	$(INSTALL_DIR) $(1)/usr/share/honk
	$(INSTALL_DATA) $(CURDIR)/files/config.dae $(1)/usr/share/honk/default-config.dae
	# Provenance is only generated by a source build; a plain feed build has
	# no such file and must still install cleanly.
	if [ -f $(CURDIR)/generated-provenance.json ]; then \
		$(INSTALL_DATA) $(CURDIR)/generated-provenance.json $(1)/usr/share/honk/provenance.json; \
	fi
	$(INSTALL_BIN) $(CURDIR)/files/control.sh $(1)/usr/share/honk/control.sh
	$(INSTALL_BIN) $(CURDIR)/files/lock.sh $(1)/usr/share/honk/lock.sh
	$(INSTALL_BIN) $(CURDIR)/files/lifecycle.sh $(1)/usr/share/honk/lifecycle.sh
	$(INSTALL_BIN) $(CURDIR)/files/geodata.sh $(1)/usr/share/honk/geodata.sh
	$(INSTALL_BIN) $(CURDIR)/files/maintenance.sh $(1)/usr/share/honk/maintenance.sh
	$(INSTALL_BIN) $(CURDIR)/files/job.sh $(1)/usr/share/honk/job.sh
	$(INSTALL_BIN) $(CURDIR)/files/update.sh $(1)/usr/share/honk/update.sh
	$(INSTALL_BIN) $(CURDIR)/files/redact-log.sh $(1)/usr/share/honk/redact-log.sh
	$(INSTALL_BIN) $(CURDIR)/files/log-level-filter.sh $(1)/usr/share/honk/log-level-filter.sh
	$(INSTALL_DATA) $(CURDIR)/files/log-lines.sh $(1)/usr/share/honk/log-lines.sh
endef

$(eval $(call BuildPackage,honk))
