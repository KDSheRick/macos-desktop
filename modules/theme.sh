#!/usr/bin/env bash
# 主题 / 图标 / 光标（来自 vinceliuice 的 MacTahoe 系列，GPL 第三方项目，按需下载）
GTK_THEME_REPO="https://github.com/vinceliuice/MacTahoe-gtk-theme.git"
ICON_THEME_REPO="https://github.com/vinceliuice/MacTahoe-icon-theme.git"
CURSOR_THEME_REPO="https://github.com/vinceliuice/WhiteSur-cursors.git"

module_theme() {
    local src="$USER_HOME/.cache/macos-desktop-src"
    mkdir -p "$src"

    # ---- GTK + GNOME Shell 主题 ----
    if [[ -d "$THEMES_DIR/MacTahoe-Dark" ]] && ! $FORCE; then
        ok "  GTK/Shell 主题已存在（MacTahoe-Dark）"
    else
        info "  下载并安装 MacTahoe 主题…"
        [[ -d "$src/MacTahoe-gtk-theme" ]] || run git clone --depth=1 "$GTK_THEME_REPO" "$src/MacTahoe-gtk-theme"
        run_sh "cd '$src/MacTahoe-gtk-theme' && ./install.sh -c dark >/dev/null"
        mark_added "$THEMES_DIR/MacTahoe-Dark"
        mark_added "$THEMES_DIR/MacTahoe-Dark-hdpi"
        mark_added "$THEMES_DIR/MacTahoe-Dark-xhdpi"
    fi

    # ---- 图标 ----
    if [[ -d "$ICONS_DIR/MacTahoe-dark" ]] && ! $FORCE; then
        ok "  图标主题已存在（MacTahoe-dark）"
    else
        info "  下载并安装 MacTahoe 图标…"
        [[ -d "$src/MacTahoe-icon-theme" ]] || run git clone --depth=1 "$ICON_THEME_REPO" "$src/MacTahoe-icon-theme"
        run_sh "cd '$src/MacTahoe-icon-theme' && ./install.sh >/dev/null"
        mark_added "$ICONS_DIR/MacTahoe-dark"
    fi

    # ---- 光标（MacTahoe 没有单独的 cursors 仓库，用同作者的 WhiteSur-cursors）----
    # 光标可以放在 ~/.icons 或 ~/.local/share/icons（都算已安装）
    local cursor_name=""
    if [[ -d "$CURSORS_DIR/MacTahoe-cursors" || -d "$ICONS_DIR/MacTahoe-cursors" ]] && ! $FORCE; then
        cursor_name="MacTahoe-cursors"
        ok "  光标主题已存在（MacTahoe-cursors）"
    elif [[ -d "$CURSORS_DIR/WhiteSur-cursors" || -d "$ICONS_DIR/WhiteSur-cursors" ]] && ! $FORCE; then
        cursor_name="WhiteSur-cursors"
        ok "  光标主题已存在（WhiteSur-cursors）"
    else
        info "  下载并安装 macOS 风格光标（WhiteSur-cursors）…"
        [[ -d "$src/WhiteSur-cursors" ]] || run git clone --depth=1 "$CURSOR_THEME_REPO" "$src/WhiteSur-cursors"
        run_sh "cd '$src/WhiteSur-cursors' && ./install.sh >/dev/null"
        cursor_name="WhiteSur-cursors"
        mark_added "$CURSORS_DIR/WhiteSur-cursors"
    fi
    run gsettings set org.gnome.desktop.interface cursor-theme "$cursor_name"
    ok "  主题模块完成"
}
