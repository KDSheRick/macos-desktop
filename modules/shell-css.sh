#!/usr/bin/env bash
# GNOME Shell 用户主题 + 「快捷设置玻璃」补丁
#   MacTahoe 主题把快捷设置写得几乎全透明，这里追加一段深色玻璃样式（可删）

module_shell_css() {
    backup_dconf /org/gnome/shell/extensions/user-theme/
    dconf_apply /org/gnome/shell/extensions/user-theme/ "$DIR/assets/dconf/user-theme.conf"

    local css="$THEMES_DIR/MacTahoe-Dark/gnome-shell/gnome-shell.css"
    if [[ ! -f "$css" ]]; then
        warn "  找不到 $css，跳过快捷设置补丁"
        return 0
    fi

    if grep -qE "macos-desktop 玻璃补丁|opencode 修复" "$css"; then
        ok "  快捷设置玻璃补丁已存在"
    else
        backup_file "$css"
        info "  追加「快捷设置玻璃」补丁"
        run_sh "cat '$DIR/assets/quick-settings-glass.css' >> '$css'"
    fi

    # 热重载主题（不注销也能看到效果）
    run_sh "bash '$DIR/assets/reload-shell-theme.sh' >/dev/null 2>&1 || true"
    ok "  Shell 主题设置完成"
}
