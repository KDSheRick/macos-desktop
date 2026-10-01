#!/usr/bin/env bash
# 公共函数：日志、确认、命令包装（支持 --dry-run）
# 由 install.sh / restore.sh 共同 source

# ---------------------------------------------------------------- 输出

if [[ -t 1 ]]; then
    C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'
    C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'
else
    C_RESET=''; C_BOLD=''; C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''
fi

info()  { echo "${C_BLUE}i${C_RESET} $*"; }
ok()    { echo "${C_GREEN}✓${C_RESET} $*"; }
warn()  { echo "${C_YELLOW}!${C_RESET} $*" >&2; }
die()   { echo "${C_RED}✗ $*${C_RESET}" >&2; exit 1; }

banner() {
    echo "${C_BOLD}macOS 风格桌面一键安装${C_RESET}"
    echo "  Ubuntu + GNOME 50 + Wayland · 可一键还原"
    echo
}

confirm() {
    if $ASSUME_YES; then return 0; fi
    read -r -p "$1 [Y/n] " answer
    [[ -z "$answer" || "$answer" =~ ^[Yy] ]]
}

# ---------------------------------------------------------------- 命令包装

# 执行命令；--dry-run 时只打印
run() {
    if $DRY_RUN; then
        echo "    [dry-run] $*"
        return 0
    fi
    "$@"
}

# 执行 shell 字符串（可以带重定向），dry-run 时只打印
run_sh() {
    if $DRY_RUN; then
        echo "    [dry-run] $*"
        return 0
    fi
    bash -c "$*"
}

have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------- 路径

USER_HOME="${HOME}"
THEMES_DIR="$USER_HOME/.themes"
ICONS_DIR="$USER_HOME/.local/share/icons"
CURSORS_DIR="$USER_HOME/.icons"
FONTS_DIR="$USER_HOME/.local/share/fonts"
EXTENSIONS_DIR="$USER_HOME/.local/share/gnome-shell/extensions"
APPS_DIR="$USER_HOME/.local/share/applications"

# 本项目依赖的贴纸/灵动岛仓库
# 查找顺序：环境变量 → 与本项目同级的 desktop-stickers → ~/desktop-stickers → 默认克隆位置
DESKTOP_STICKERS_REPO="https://github.com/KDSheRick/desktop-stickers.git"
if [[ -z "${DESKTOP_STICKERS_DIR:-}" ]]; then
    if [[ -f "$DIR/../desktop-stickers/main.py" ]]; then
        DESKTOP_STICKERS_DIR="$(cd "$DIR/.." && pwd)/desktop-stickers"
    else
        DESKTOP_STICKERS_DIR="$USER_HOME/desktop-stickers"
    fi
fi

# 扩展 uuid（与 metadata.json 保持一致）
ISLAND_UUID="lyrics-panel@loong"
BLUR_UUID="blur-my-shell@aunetx"
USER_THEME_UUID="user-theme@gnome-shell-extensions.gcampax.github.com"

BACKUP_DIR=""
MANIFEST=""

# ---------------------------------------------------------------- dconf

# 应用 dconf 片段（片段里是 [/] + 键值，对应下面的路径）
dconf_apply() {
    local path="$1" file="$2"
    [[ -f "$file" ]] || { warn "缺少 dconf 片段：$file"; return 0; }
    info "  写入设置 $path"
    run_sh "dconf load '$path' < '$file'"
}
