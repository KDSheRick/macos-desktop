#!/usr/bin/env bash
# 毛玻璃（Blur my Shell）
#   - 桌面贴纸窗口模糊（白名单 *SysStickers*）
#   - Dock / 概览 / 弹窗模糊
#   - 应用模糊圆角 25（与贴纸卡片圆角 16 + 窗口留白 9 同心）

module_blur() {
    local uuid="blur-my-shell@aunetx"
    if ! [[ "$(gnome-extensions list 2>/dev/null || true)" == *"$uuid"* ]]; then
        warn "  没装 Blur my Shell，跳过（稍后 extensions 模块会尝试安装）"
        return 0
    fi
    backup_dconf /org/gnome/shell/extensions/blur-my-shell/
    dconf_apply /org/gnome/shell/extensions/blur-my-shell/ "$DIR/assets/dconf/blur.conf"
    run gnome-extensions enable "$uuid"
    warn "  注意：Blur my Shell 的设置在扩展版本不同（非 v73）时可能部分失效"
    ok "  毛玻璃设置完成"
}
