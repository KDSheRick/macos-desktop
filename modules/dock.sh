#!/usr/bin/env bash
# Dock（Ubuntu 自带的 ubuntu-dock 扩展，用的是 dash-to-dock 的设置）
#   底部居中 / 自动隐藏 / 48px / 0.6 透明 / DOT 运行指示

module_dock() {
    local uuid="ubuntu-dock@ubuntu.com"
    if [[ -d "$EXTENSIONS_DIR/$uuid" ]] || [[ "$(gnome-extensions list 2>/dev/null || true)" == *"$uuid"* ]]; then
        backup_dconf /org/gnome/shell/extensions/dash-to-dock/
        dconf_apply /org/gnome/shell/extensions/dash-to-dock/ "$DIR/assets/dconf/dock.conf"
        run gnome-extensions enable "$uuid"
        ok "  Dock 设置完成（可能需要注销后完全生效）"
    else
        warn "  没有找到 ubuntu-dock 扩展，跳过 Dock 设置"
    fi
}
