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
	# 只认我们自己写的那一对地址：别的写法是用户自己的配置。
	if grep -q 'Loyalsoldier/v2ray-rules-dat/release/geosite.dat' "$1" &&
		grep -q 'Loyalsoldier/v2ray-rules-dat/release/geoip.dat' "$1"; then
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
