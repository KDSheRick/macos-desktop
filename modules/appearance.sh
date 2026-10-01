#!/usr/bin/env bash
# 外观基础设置：深色模式、窗口按钮（左侧）、字体、触控板、mutter

module_appearance() {
    backup_dconf /org/gnome/desktop/interface/
    backup_dconf /org/gnome/desktop/wm/preferences/
    backup_dconf /org/gnome/desktop/peripherals/touchpad/
    backup_dconf /org/gnome/mutter/

    dconf_apply /org/gnome/desktop/interface/ "$DIR/assets/dconf/interface.conf"
    dconf_apply /org/gnome/desktop/wm/preferences/ "$DIR/assets/dconf/wm.conf"
    dconf_apply /org/gnome/desktop/peripherals/touchpad/ "$DIR/assets/dconf/touchpad.conf"
    dconf_apply /org/gnome/mutter/ "$DIR/assets/dconf/mutter.conf"

    # 字体：SF Pro 是苹果专有字体，不能随包分发
    local installed_fonts=""
    have fc-list && installed_fonts="$(fc-list 2>/dev/null || true)"
    if [[ "$installed_fonts" == *"SF Pro Display"* || "$installed_fonts" == *"SF Pro Text"* ]]; then
        ok "  检测到 SF Pro 字体"
    else
        warn "  没检测到 SF Pro Display：字体保持系统默认（想一致请自行安装；项目里不含该字体）"
        run gsettings reset org.gnome.desktop.interface font-name
        run gsettings reset org.gnome.desktop.interface document-font-name
        run gsettings reset org.gnome.desktop.wm.preferences titlebar-font
    fi
    ok "  外观设置完成"
}
