#!/usr/bin/env bash
# 环境检查：目标平台是 Ubuntu + GNOME 50 + Wayland（与作者机器一致）
# 不符合时给出警告；加 --force 可以继续

check_environment() {
    local problems=()

    # 发行版
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        local id version_id
        id="$(. /etc/os-release && echo "${ID:-}")"
        version_id="$(. /etc/os-release && echo "${VERSION_ID:-}")"
        if [[ "$id" != "ubuntu" ]]; then
            problems+=("不是 Ubuntu（检测到：${id:-未知}）")
        fi
        info "系统：Ubuntu ${version_id:-?}"
    else
        problems+=("读不到 /etc/os-release")
    fi

    # GNOME Shell 版本
    if have gnome-shell; then
        local shell_version
        shell_version="$(gnome-shell --version | awk '{print $3}')"
        info "GNOME Shell：$shell_version"
        [[ "$shell_version" == 50* ]] || problems+=("GNOME Shell 不是 50（检测到 $shell_version）")
    else
        problems+=("没有 gnome-shell")
    fi

    # 会话类型（扩展与主题热重载都依赖）
    local session="${XDG_SESSION_TYPE:-}"
    if [[ "$session" != "wayland" ]]; then
        problems+=("当前不是 Wayland 会话（检测到：${session:-未知}）")
    fi

    # 需要的命令
    for cmd in dconf gsettings git unzip curl; do
        have "$cmd" || problems+=("缺少命令：$cmd")
    done

    # Ubuntu 专属扩展（Dock / 托盘歌词都依赖）
    if have gsettings; then
        local enabled
        enabled="$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null || true)"
        [[ "$enabled" == *ubuntu-dock* ]] || problems+=("未启用 ubuntu-dock 扩展（Dock 设置会无效）")
        [[ "$enabled" == *ubuntu-appindicators* ]] || problems+=("未启用 ubuntu-appindicators 扩展")
    fi

    if ((${#problems[@]})); then
        echo
        warn "环境与作者机器不一致，可能无法完全复现："
        printf '  - %s\n' "${problems[@]}"
        echo
        if ! $FORCE; then
            if ! confirm "仍然继续吗？（不推荐；建议只在 Ubuntu + GNOME 50 + Wayland 上使用）"; then
                die "已取消"
            fi
        fi
    else
        ok "环境检查通过（Ubuntu + GNOME 50 + Wayland）"
    fi
}
