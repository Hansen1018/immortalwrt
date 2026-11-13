#!/bin/sh

# 地理数据的下载源：旧版本在 system.dae 里写死了它。
#
# 旧版本写的是：一个 GitHub 地址（每个文件一个）+ route: direct。这段配置会
# 覆盖核心自己的内置列表（MetaCubeX 的两个地址，一个不通就换下一个），于是
# 只剩一个地址可试 —— 那个地址在墙内不通，面板的「立即更新」就停在下载阶段
# （下载超时）。route: direct 还绕过了路由规则，出口不由用户决定。
#
# 现在配置里不写这一段：核心用内置的列表，路由规则决定出口。设备上留下的
# 旧文件（以及旧备份里的）里这段只在它确实是我们写的那份时才去掉：用户自己
# 改过的配置不动。

# honk_geodata_strip <in> <out>
#   把 <in> 里的旧下载源去掉写进 <out>。<out> 和 <in> 一样时也是返回 0：
#   调用方要的是「没有旧下载源的文件」，而不是「有没有改动过」。
honk_geodata_strip() {
	[ -f "$1" ] && [ ! -L "$1" ] || return 1
	# 只认我们自己写的那个地址（Loyalsoldier）：别的写法是用户自己的配置。
	# 两个地址都在、只写了 geosite、或者换了写法，都算我们写的那份，都去掉。
	if grep -q 'Loyalsoldier' "$1"; then
		awk '
			# 这两行注释是跟着下载源一起写的，删段就一起删。
			/^# 地理数据的下载源：与核心配置/ { next }
			/^# 面板更新与 LuCI 更新拿到的字节一致/ { next }
			/^assets \{$/ { skip = 1; next }
			skip && /^\}$/ { skip = 0; drop_blank = 1; next }
			skip { next }
			# 段后面那个空行也一起去掉，文件才和新生成的那份一样。
			drop_blank { drop_blank = 0; if ($0 == "") next }
			{ print }
		' "$1" > "$2" || return 1
		grep -q 'Loyalsoldier' "$2" && return 1
		return 0
	fi
	cp -p "$1" "$2" || return 1
	return 0
}

# 地理数据的下载源列表：上游原版的两个地址在前（MetaCubeX 的 raw 与
# jsDelivr），我们自己那份 Loyalsoldier 在后当兜底 —— 一个不通就换下一个。
#
# 为什么是四个而不是配置文件里的一个：核心的配置文件每个文件只能写一个地址
# （geosite_download_url / geoip_download_url），写死一个就没有退路 —— 面板的
# 「立即更新」当初就是只试了那个墙内不通的地址才一直失败。库里可以存最多四个
# （MAX_URLS=4），是面板写的那种补丁（from_config=false）：配置文件不写地址
# 时它就一直留着，核心按顺序一个一个试。
#
# 面板的「立即更新」与 LuCI 的「更新」用同一份列表、同一个顺序，两条路径拿到
# 的字节才一样，不会互相覆盖。
#
# honk_geodata_sources <geosite|geoip>
#   打印这个文件要试的地址，一个一行，按顺序。
honk_geodata_sources() {
	case "$1" in
	geosite)
		printf '%s\n' \
			'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/release/geosite.dat' \
			'https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat' \
			'https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat' \
			'https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat'
		;;
	geoip)
		printf '%s\n' \
			'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/release/geoip.dat' \
			'https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat' \
			'https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat' \
			'https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat'
		;;
	*) return 1 ;;
	esac
}
