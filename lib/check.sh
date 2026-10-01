#!/usr/bin/env bash
# 环境检查：逐项核对「当前环境」是否与「目标环境」一致，并给出报告
#
# 目标环境（作者机器，效果以此为准）：
#   Ubuntu + GNOME Shell 50 + Wayland + ubuntu-dock / ubuntu-appindicators
#
# 结果写入：
#   CHECK_PROBLEM  - 会导致装不好的硬性问题（数组）
#   CHECK_NOTE     - 提示，可忽略（数组）
#   CHECK_MATCH / CHECK_TOTAL - 通过项 / 总项

TARGET_DESC="Ubuntu + GNOME Shell 50 + Wayland"
CHECK_PROBLEMS=()
CHECK_NOTES=()
CHECK_MATCH=0
CHECK_TOTAL=0

CHECK_ROW_WIDTH=22

# check_row <ok|warn|bad> <项目> <实际值> [影响说明]
check_row() {
    local level="$1" name="$2" value="$3" impact="${4:-}"
    local mark color
    case "$level" in
        ok)   mark="✓"; color="$C_GREEN" ;;
        warn) mark="!"; color="$C_YELLOW" ;;
        bad)  mark="✗"; color="$C_RED" ;;
    esac
    printf '  %s%s%s %-*s %s\n' "$color" "$mark" "$C_RESET" "$CHECK_ROW_WIDTH" "$name" "$value"
    CHECK_TOTAL=$((CHECK_TOTAL + 1))
    if [[ "$level" == "ok" ]]; then CHECK_MATCH=$((CHECK_MATCH + 1)); fi
    [[ -n "$impact" ]] && printf '      %s\n' "$impact"
    case "$level" in
        bad)  CHECK_PROBLEMS+=("$name：$value") ;;
        warn) CHECK_NOTES+=("$name：$value") ;;
    esac
}

# 小工具：把命令数组里缺失的命令找出来
missing_commands() {
    local missing=()
    local c
    for c in "$@"; do
        have "$c" || missing+=("$c")
    done
    if ((${#missing[@]})); then
        echo "${missing[*]}"
    fi
    return 0
}

check_environment() {
    echo "${C_BOLD}环境检查${C_RESET}（目标环境：$TARGET_DESC）"
    echo "────────────────────────────────────────────────────────────"

    # ---- 1. 发行版 ----
    local distro="未知" distro_ok=bad
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        distro="$(. /etc/os-release && echo "${PRETTY_NAME:-${ID:-未知}}")"
        # shellcheck disable=SC1091
        if [[ "$(. /etc/os-release && echo "${ID:-}")" == "ubuntu" ]]; then
            distro_ok=ok
        fi
    fi
    if [[ "$distro_ok" == ok ]]; then
        check_row ok "发行版" "$distro"
    else
        check_row bad "发行版" "$distro" "目标要求 Ubuntu（其他发行版包名/扩展差异较大，不保证效果）"
    fi

    # ---- 2. GNOME Shell 版本 ----
    if have gnome-shell; then
        local shell_version
        shell_version="$(gnome-shell --version 2>/dev/null | awk '{print $3}')"
        if [[ "$shell_version" == 50* ]]; then
            check_row ok "GNOME Shell" "$shell_version"
        else
            check_row bad "GNOME Shell" "$shell_version（目标 50）" \
                "主题与扩展都是按 GNOME 50 适配的；版本不同可能完全不生效"
        fi
    else
        check_row bad "GNOME Shell" "未安装" "没有 gnome-shell，无法安装主题与扩展"
    fi

    # ---- 3. 会话类型 ----
    local session="${XDG_SESSION_TYPE:-未知}"
    if [[ "$session" == "wayland" ]]; then
        check_row ok "会话类型" "wayland"
    else
        check_row bad "会话类型" "$session（目标 wayland）" \
            "X11 会话下部分效果（缩放、扩展热重载）不一样"
    fi

    # ---- 4. 必备命令 ----
    local need=(dconf gsettings git curl unzip python3 timeout)
    local missing
    missing="$(missing_commands "${need[@]}")"
    if [[ -z "$missing" ]]; then
        check_row ok "必备命令" "${need[*]}"
    else
        check_row bad "必备命令" "缺少：$missing" "先安装缺少的命令再继续（apt install …）"
    fi

    # ---- 5. Ubuntu 桌面组件 ----
    local dock_ok=no appind_ok=no
    if have gnome-extensions; then
        local exts
        exts="$(gnome-extensions list 2>/dev/null || true)"
        [[ "$exts" == *ubuntu-dock@ubuntu.com* ]] && dock_ok=yes
        [[ "$exts" == *ubuntu-appindicators@ubuntu.com* ]] && appind_ok=yes
    fi
    if [[ "$dock_ok" == yes && "$appind_ok" == yes ]]; then
        check_row ok "桌面组件" "ubuntu-dock ✓  ubuntu-appindicators ✓"
    elif [[ "$dock_ok" == no && "$appind_ok" == no ]]; then
        check_row bad "桌面组件" "缺少 ubuntu-dock / ubuntu-appindicators" \
            "Dock 设置与顶栏歌词依赖这两个 Ubuntu 自带扩展"
    else
        check_row warn "桌面组件" "ubuntu-dock=$dock_ok  ubuntu-appindicators=$appind_ok" \
            "缺的那个相关功能会失效"
    fi

    # ---- 6. 用户扩展总开关（开着的话所有第三方扩展都不加载）----
    local user_ext="unknown"
    if have gsettings; then
        user_ext="$(gsettings get org.gnome.shell disable-user-extensions 2>/dev/null || echo unknown)"
    fi
    case "$user_ext" in
        false) check_row ok "用户扩展总开关" "已开启（可以加载第三方扩展）" ;;
        true)  check_row bad "用户扩展总开关" "已关闭（disable-user-extensions=true）" \
                   "开关关闭时所有第三方扩展都不会加载；安装脚本会帮你打开" ;;
        *)     check_row warn "用户扩展总开关" "读取失败（$user_ext）" ;;
    esac

    # ---- 7. 磁盘空间 ----
    local free_gb
    free_gb="$(df -BG --output=avail "$USER_HOME" 2>/dev/null | tail -1 | tr -dc '0-9' || true)"
    if [[ -n "$free_gb" ]]; then
        if ((free_gb >= 1)); then
            check_row ok "磁盘空间" "可用 ${free_gb} GB（需要约 1 GB）"
        else
            check_row bad "磁盘空间" "可用 ${free_gb} GB" "主题/图标/扩展大约需要 1 GB"
        fi
    else
        check_row warn "磁盘空间" "读取失败"
    fi

    # ---- 8. 网络（只在需要下载时用到）----
    local net_github=no net_ego=no
    if have curl; then
        curl -fsS --max-time 6 -o /dev/null https://github.com 2>/dev/null && net_github=yes
        curl -fsS --max-time 6 -o /dev/null https://extensions.gnome.org 2>/dev/null && net_ego=yes
    fi
    if [[ "$net_github" == yes && "$net_ego" == yes ]]; then
        check_row ok "网络" "github.com ✓  extensions.gnome.org ✓"
    else
        check_row warn "网络" "github.com=$net_github  extensions.gnome.org=$net_ego" \
            "只在需要下载主题/扩展时用到；已装好的会自动跳过"
    fi

    echo
    print_current_state
    echo
    echo "────────────────────────────────────────────────────────────"
    printf '  匹配 %s/%s 项' "$CHECK_MATCH" "$CHECK_TOTAL"
    if ((${#CHECK_PROBLEMS[@]})); then
        printf '，%s%d 项不匹配%s' "$C_RED" "${#CHECK_PROBLEMS[@]}" "$C_RESET"
    fi
    if ((${#CHECK_NOTES[@]})); then
        printf '，%s%d 项提示%s' "$C_YELLOW" "${#CHECK_NOTES[@]}" "$C_RESET"
    fi
    echo
    if ((${#CHECK_PROBLEMS[@]})); then
        echo
        echo "  ${C_RED}不匹配的项目：${C_RESET}"
        printf '    - %s\n' "${CHECK_PROBLEMS[@]}"
    fi
    if ((${#CHECK_NOTES[@]})); then
        echo "  ${C_YELLOW}提示：${C_RESET}"
        printf '    - %s\n' "${CHECK_NOTES[@]}"
    fi
    echo
}

# 现状摘要：已经符合目标的部分（安装时会自动跳过）
print_current_state() {
    echo "${C_BOLD}现状${C_RESET}（已符合目标的会自动跳过）"
    local ok_txt="${C_GREEN}✓${C_RESET}" miss_txt="${C_YELLOW}·${C_RESET}"

    # 主题 / 图标 / 光标
    if [[ -d "$THEMES_DIR/MacTahoe-Dark" && -d "$ICONS_DIR/MacTahoe-dark" ]] &&
       [[ -d "$CURSORS_DIR/MacTahoe-cursors" || -d "$ICONS_DIR/MacTahoe-cursors" ]]; then
        printf '  %s %s\n' "$ok_txt" "主题 / 图标 / 光标"
    else
        printf '  %s %s\n' "$miss_txt" "主题 / 图标 / 光标（未装全，将下载安装）"
    fi

    # Dock 设置
    if [[ "$(dconf read /org/gnome/shell/extensions/dash-to-dock/dock-position 2>/dev/null)" == "'BOTTOM'" ]]; then
        printf '  %s %s\n' "$ok_txt" "Dock 设置"
    else
        printf '  %s %s\n' "$miss_txt" "Dock 设置（将写入）"
    fi

    # 毛玻璃设置（白名单里应有贴纸）
    if [[ "$(dconf read /org/gnome/shell/extensions/blur-my-shell/applications/whitelist 2>/dev/null)" == *SysStickers* ]]; then
        printf '  %s %s\n' "$ok_txt" "毛玻璃设置（含贴纸模糊白名单）"
    else
        printf '  %s %s\n' "$miss_txt" "毛玻璃设置（将写入）"
    fi

    # 快捷设置玻璃补丁
    local css="$THEMES_DIR/MacTahoe-Dark/gnome-shell/gnome-shell.css"
    if [[ -f "$css" ]] && grep -qE "macos-desktop 玻璃补丁|opencode 修复" "$css"; then
        printf '  %s %s\n' "$ok_txt" "快捷设置玻璃补丁"
    else
        printf '  %s %s\n' "$miss_txt" "快捷设置玻璃补丁（将追加）"
    fi

    # 桌面贴纸
    if [[ -f "$DESKTOP_STICKERS_DIR/main.py" ]]; then
        printf '  %s %s\n' "$ok_txt" "桌面贴纸（$DESKTOP_STICKERS_DIR）"
    else
        printf '  %s %s\n' "$miss_txt" "桌面贴纸（将克隆并安装）"
    fi

    # 灵动岛扩展
    if [[ -f "$EXTENSIONS_DIR/$ISLAND_UUID/island.js" ]]; then
        printf '  %s %s\n' "$ok_txt" "灵动岛扩展"
    else
        printf '  %s %s\n' "$miss_txt" "灵动岛扩展（将安装）"
    fi
}

# 是否有硬性问题（供安装流程决定默认选项）
check_has_problems() { ((${#CHECK_PROBLEMS[@]} > 0)); }
