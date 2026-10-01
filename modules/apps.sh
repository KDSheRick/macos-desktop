#!/usr/bin/env bash
# 桌面贴纸 + 顶栏歌词 + 灵动岛（来自本项目依赖的 desktop-stickers 仓库）

module_apps() {
    if [[ -d "$DESKTOP_STICKERS_DIR/.git" ]]; then
        ok "  贴纸仓库已存在：$DESKTOP_STICKERS_DIR"
        # 尝试更新（网络慢/被墙就跳过，限时 20 秒，绝不卡住安装）
        run_sh "timeout 20 git -C '$DESKTOP_STICKERS_DIR' pull --ff-only >/dev/null 2>&1 || true"
    else
        info "  克隆 desktop-stickers 到 $DESKTOP_STICKERS_DIR"
        run mkdir -p "$(dirname "$DESKTOP_STICKERS_DIR")"
        if ! run git clone --depth=1 "$DESKTOP_STICKERS_REPO" "$DESKTOP_STICKERS_DIR"; then
            rm -rf "$DESKTOP_STICKERS_DIR"
            die "克隆失败。请手动克隆，或用 DESKTOP_STICKERS_DIR=/已有路径 bash install.sh 指定目录"
        fi
        mark_added "$DESKTOP_STICKERS_DIR"
    fi

    # 安装前记下“已经存在”的东西；装完只把“新出现的”登记到 manifest（还原时才删除）
    local candidates=(
        "$USER_HOME/.config/autostart/sysstickers.desktop"
        "$USER_HOME/.local/share/applications/sysstickers.desktop"
        "$USER_HOME/.local/share/applications/sysstickers-lyrics.desktop"
        "$USER_HOME/.local/share/applications/sysstickers-control.desktop"
        "$USER_HOME/.config/sysstickers"
    )
    local pre_existing=()
    local p q
    for p in "${candidates[@]}"; do
        if [[ -e "$p" ]]; then
            pre_existing+=("$p")
        fi
    done

    # 贴纸自己的安装脚本：依赖检查 + 开机自启 + 应用菜单 + 启动 + 开模糊
    info "  运行贴纸安装脚本（依赖 / 自启 / 菜单 / 启动）"
    run_sh "cd '$DESKTOP_STICKERS_DIR' && bash install.sh >/dev/null"

    for p in "${candidates[@]}"; do
        [[ -e "$p" ]] || continue
        local existed=false
        for q in "${pre_existing[@]}"; do
            if [[ "$q" == "$p" ]]; then
                existed=true
            fi
        done
        if ! $existed; then
            mark_added "$p"
        fi
    done

    ok "  贴纸应用安装完成"
}
