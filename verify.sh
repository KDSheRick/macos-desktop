#!/usr/bin/env bash
# 安装后自检：对照作者机器逐项检查（只读，不改任何东西）
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$DIR/lib/common.sh"

PASS=0; FAIL=0; WARN=0
check_eq() { # 说明 期望 实际
    if [[ "$2" == "$3" ]]; then ok "  $1"; ((PASS++)); else warn "  $1（期望 $2，实际 $3）"; ((FAIL++)); fi
}
check_has() { # 说明 文件/目录
    if [[ -e "$2" ]]; then ok "  $1"; ((PASS++)); else warn "  $1（缺少 $2）"; ((FAIL++)); fi
}
check_true() { # 说明 命令输出
    if [[ "$2" == "true" ]]; then ok "  $1"; ((PASS++)); else warn "  $1（实际 $2）"; ((FAIL++)); fi
}

banner
echo "自检开始"
echo
info "系统与主题"
check_eq "GTK 主题"        "'MacTahoe-Dark'" "$(gsettings get org.gnome.desktop.interface gtk-theme)"
check_eq "图标主题"        "'MacTahoe-dark'" "$(gsettings get org.gnome.desktop.interface icon-theme)"
check_eq "深色模式"        "'prefer-dark'"   "$(gsettings get org.gnome.desktop.interface color-scheme)"
check_eq "窗口按钮在左"    "'close,minimize,maximize:'" "$(gsettings get org.gnome.desktop.wm.preferences button-layout)"
local_theme="$(dconf read /org/gnome/shell/extensions/user-theme/name | tr -d "'")"
check_eq "Shell 用户主题"  "MacTahoe-Dark" "$local_theme"

echo
info "Dock / 毛玻璃"
check_eq "Dock 位置"       "'BOTTOM'" "$(gsettings get org.gnome.shell.extensions.dash-to-dock dock-position 2>/dev/null || echo '?')"
check_eq "Dock 自动隐藏"   "true"     "$(gsettings get org.gnome.shell.extensions.dash-to-dock autohide 2>/dev/null || echo '?')"
check_eq "贴纸模糊白名单"  "['*SysStickers*', '*sysstickers*']" "$(dconf read /org/gnome/shell/extensions/blur-my-shell/applications/whitelist)"
check_eq "模糊圆角"        "25"       "$(dconf read /org/gnome/shell/extensions/blur-my-shell/applications/corner-radius)"
css="$USER_HOME/.themes/MacTahoe-Dark/gnome-shell/gnome-shell.css"
if [[ -f "$css" ]] && grep -qE "macos-desktop 玻璃补丁|opencode 修复" "$css"; then ok "  快捷设置玻璃补丁"; ((PASS++)); else warn "  快捷设置玻璃补丁（未找到）"; ((FAIL++)); fi

echo
info "扩展"
check_has "user-theme 已安装" "$EXTENSIONS_DIR/user-theme@gnome-shell-extensions.gcampax.github.com"
check_has "Blur my Shell 已安装" "$EXTENSIONS_DIR/blur-my-shell@aunetx"
check_has "灵动岛已安装"    "$EXTENSIONS_DIR/lyrics-panel@loong"
for uuid in user-theme@gnome-shell-extensions.gcampax.github.com blur-my-shell@aunetx lyrics-panel@loong; do
    state="$(gnome-extensions info "$uuid" 2>/dev/null | awk -F: '/状态/{print $2}' | tr -d ' ')"
    if [[ "$state" == "ACTIVE" ]]; then ok "  $uuid 运行中"; ((PASS++));
    elif [[ "$state" == "INITIALIZED" || -z "$state" ]]; then warn "  $uuid 未生效（注销重登后再看）"; ((WARN++));
    else warn "  $uuid 状态：$state"; ((FAIL++)); fi
done

echo
info "贴纸 / 灵动岛"
check_has "贴纸应用" "$DESKTOP_STICKERS_DIR/main.py"
check_has "开机自启" "$USER_HOME/.config/autostart/sysstickers.desktop"
check_has "灵动岛扩展目录" "$EXTENSIONS_DIR/lyrics-panel@loong/island.js"

echo
echo "${C_BOLD}结果：${C_GREEN}$PASS 通过${C_RESET}，${C_YELLOW}$FAIL 待处理${C_RESET}，$WARN 提示"
if ((FAIL > 0)); then
    echo "提示：多数项在「注销并重新登录」后会转为通过；仍不通过可用 restore.sh 还原。"
fi
