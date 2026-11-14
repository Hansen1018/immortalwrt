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


# 地理数据的下载源列表：上游原版那一份（MetaCubeX 的 raw 与 jsDelivr 镜像），
# 也就是核心自己的内置列表。
#
# 面板的下拉是按「来源」（它那边叫 tag）匹配的：metacubex / metacubex-lite /
# loyalsoldier。一个列表只能是一个来源：混着两个来源它认不出来，会落回
# 「自定义」把几个地址一起塞进去；兜底时还可能换到另一份规则集（分类对不
# 上，更新会被核心拒掉）。
#
# 所以这里一份清单就是一个来源的镜像组：raw 加几个 jsDelivr 节点，一个不通
# 就换下一个 —— 拿到的始终是同一份文件（同一份规则集，分类才对得上）。
#
# 面板的「立即更新」与 LuCI 的「更新」用同一份列表、同一个顺序，两条路径拿到
# 的字节才一样，不会互相覆盖。
#
# honk_geodata_sources <geosite|geoip>
#   默认那一份（上游原版：MetaCubeX）的地址，一个一行，按顺序。
honk_geodata_sources() {
	case "$1" in
	geosite)
		printf '%s\n' \
			'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/release/geosite.dat' \
			'https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat'
		;;
	geoip)
		printf '%s\n' \
			'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/release/geoip.dat' \
			'https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat'
		;;
	*) return 1 ;;
	esac
}

# 面板里的另一个来源：MetaCubeX 的精简版（同一个仓库，小一点的文件）。
honk_geodata_lite_sources() {
	case "$1" in
	geosite)
		printf '%s\n' \
			'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/release/geosite-lite.dat' \
			'https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite-lite.dat'
		;;
	geoip)
		printf '%s\n' \
			'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/release/geoip-lite.dat' \
			'https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip-lite.dat'
		;;
	*) return 1 ;;
	esac
}

# 第三个来源：Loyalsoldier 的 v2ray-rules-dat（同样是 raw 加 jsDelivr 镜像）。
honk_geodata_loyal_sources() {
	case "$1" in
	geosite)
		printf '%s\n' \
			'https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat' \
			'https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat'
		;;
	geoip)
		printf '%s\n' \
			'https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat' \
			'https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat'
		;;
	*) return 1 ;;
	esac
}

# 这个地址属于哪个来源：打印「来源 名 文件类型」（geosite / geoip），
# 认不出来就返回 1。用来把用户填的一个地址还原成它那一组镜像。
honk_geodata_source_of() {
	case "$1" in
	'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/release/geosite.dat'|'https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat')
		echo 'metacubex geosite' ;;
	'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/release/geoip.dat'|'https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat')
		echo 'metacubex geoip' ;;
	'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/release/geosite-lite.dat'|'https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite-lite.dat')
		echo 'metacubex-lite geosite' ;;
	'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/release/geoip-lite.dat'|'https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip-lite.dat')
		echo 'metacubex-lite geoip' ;;
	'https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat'|'https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat')
		echo 'loyalsoldier geosite' ;;
	'https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat'|'https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat')
		echo 'loyalsoldier geoip' ;;
	*) return 1 ;;
	esac
}

# 一个地址对应的镜像组：认得出来源就用那个来源的那一组（面板的下拉才认得出是
# 哪个来源），认不出就用它自己。
#
# 要的是那个来源里的哪个文件（geosite / geoip），地址本身是哪个文件不影响：
# 用户只填了一个的时候，另一个文件也用那个来源的 —— 一个列表只能是一个来源。
honk_geodata_list_for() {
	entry=$(honk_geodata_source_of "$1") || { printf '%s\n' "$1"; return 0; }
	src=${entry%% *}
	case "$src" in
	metacubex) honk_geodata_sources "$2" ;;
	metacubex-lite) honk_geodata_lite_sources "$2" ;;
	loyalsoldier) honk_geodata_loyal_sources "$2" ;;
	*) printf '%s\n' "$1" ;;
	esac
}

# 用户在 LuCI 里选的那一份（honk.main.<类型>_url）：选的是哪个来源就用那个
# 来源的镜像组，没选就用默认那一份。
#
# 只填了一个（另一个空着）时，两个文件都用它那一个来源 —— 一个列表只能是一
# 个来源，面板才认得出来；混着两个来源它会落回「自定义」。
honk_geodata_configured_list() {
	kind=$1
	ip=""
	site=""
	if command -v uci >/dev/null 2>&1; then
		ip=$(uci -q get honk.main.geoip_url 2>/dev/null)
		site=$(uci -q get honk.main.geosite_url 2>/dev/null)
	fi
	if [ -z "$ip" ] && [ -z "$site" ]; then
		honk_geodata_sources "$kind"
		return 0
	fi
	url=$ip
	[ "$kind" = geosite ] && url=$site
	if [ -z "$url" ]; then
		case "$kind" in
		geosite) url=$ip ;;
		*) url=$site ;;
		esac
	fi
	honk_geodata_list_for "$url" "$kind"
}
