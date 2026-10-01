#!/usr/bin/env bash
# 需要的 GNOME 扩展：user-theme（Shell 主题）、Blur my Shell、灵动岛
#   - 已安装 → 启用
#   - 未安装 → 从 extensions.gnome.org 下载，并写入“下次登录启用”列表

module_extensions() {
    ensure_extension "$USER_THEME_UUID"
    ensure_extension "$BLUR_UUID"

    # 灵动岛（本项目的扩展，用它的安装脚本）
    if [[ -f "$DESKTOP_STICKERS_DIR/island-panel/install-island.sh" ]]; then
        info "  安装灵动岛扩展（desktop-stickers/island-panel）"
        local island_enabled
        island_enabled="$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null || true)"
        if [[ "$island_enabled" != *"'$ISLAND_UUID'"* ]]; then
            mark_ext_enabled "$ISLAND_UUID"
        fi
        run_sh "bash '$DESKTOP_STICKERS_DIR/island-panel/install-island.sh' >/dev/null"
        ok "  灵动岛扩展已安装（首次需要注销重新登录）"
    else
        warn "  找不到 $DESKTOP_STICKERS_DIR/island-panel，跳过灵动岛"
    fi
}

# 确保扩展已安装且已启用（新装的会写进“登录时启用”列表，注销后生效）
ensure_extension() {
    local uuid="$1"
    if [[ -d "$EXTENSIONS_DIR/$uuid" ]]; then
        ok "  扩展已安装：$uuid"
    else
        info "  从 extensions.gnome.org 下载：$uuid"
        local url
        url="$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=$uuid&shell_version=50" \
            | python3 -c 'import json,sys; print(json.load(sys.stdin).get("download_url",""))' 2>/dev/null || true)"
        if [[ -z "$url" ]]; then
            warn "  下载地址获取失败：$uuid（可稍后手动安装）"
            return 0
        fi
        run_sh "curl -fsSL -o /tmp/$uuid.zip 'https://extensions.gnome.org$url' && \
                rm -rf '$EXTENSIONS_DIR/$uuid' && \
                mkdir -p '$EXTENSIONS_DIR/$uuid' && \
                unzip -qo /tmp/$uuid.zip -d '$EXTENSIONS_DIR/$uuid' && rm -f /tmp/$uuid.zip"
        mark_added "$EXTENSIONS_DIR/$uuid"
    fi

    # 先写入设置（下次登录必生效），再尝试即时启用。
    # 只有“原本没启用过”的才登记（还原时才去 disable）
    local enabled_list
    enabled_list="$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null || true)"
    if [[ "$enabled_list" != *"'$uuid'"* ]]; then
        mark_ext_enabled "$uuid"
    fi
    run_sh "python3 - '$uuid' <<'PY'
import ast, subprocess, sys
uuid = sys.argv[1]
raw = subprocess.run(['gsettings', 'get', 'org.gnome.shell', 'enabled-extensions'],
                     capture_output=True, text=True).stdout.strip()
try:
    items = ast.literal_eval(raw)
except Exception:
    items = []
if uuid not in items:
    items.append(uuid)
    subprocess.run(['gsettings', 'set', 'org.gnome.shell', 'enabled-extensions', str(items)])
    print('  ✓ 已加入启用列表')
PY"
    run_sh "gnome-extensions enable '$uuid' 2>/dev/null || true"
}
