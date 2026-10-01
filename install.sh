#!/usr/bin/env bash
# macOS 风格桌面一键安装（Ubuntu + GNOME 50 + Wayland）
#
#   bash install.sh                     # 一键安装（会先确认）
#   bash install.sh --yes               # 不问，直接装
#   bash install.sh --dry-run           # 只打印将要做的事
#   bash install.sh --only dock,blur    # 只装指定模块
#   bash install.sh --force             # 已存在的东西也重装
#
#   bash restore.sh                     # 一键还原到安装前
#   bash verify.sh                      # 安装后自检
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$DIR/lib/common.sh"
# shellcheck source=lib/check.sh
source "$DIR/lib/check.sh"
# shellcheck source=lib/backup.sh
source "$DIR/lib/backup.sh"

ALL_MODULES=(appearance theme dock blur shell-css apps extensions)

main() {
    parse_args "$@"
    banner

    check_environment

    if check_has_problems && ! $FORCE; then
        if $DRY_RUN; then
            warn "（dry-run）检测到不匹配项；正式安装会被拦下，确认要继续请加 --force"
        elif $ASSUME_YES; then
            die "环境不匹配，已停止（确认要继续：bash install.sh --force）"
        else
            warn "环境与目标不一致，继续可能装不好或没效果。"
            if ! confirm "仍然尝试安装吗？" no; then
                echo
                echo "已取消，未做任何修改。"
                echo "（确认要继续：bash install.sh --force）"
                exit 0
            fi
        fi
    fi

    if ! $ASSUME_YES && ! $DRY_RUN; then
        echo "${C_BOLD}本次将执行${C_RESET}（每步都会先备份，可用 restore.sh 还原）："
        printf '  - %s\n' "${MODULES[@]}"
        echo
        if ! confirm "继续安装吗？" yes; then
            echo
            echo "已取消，未做任何修改。"
            exit 0
        fi
        echo
    fi

    backup_init

    for module in "${MODULES[@]}"; do
        echo
        info "▶ $module"
        # shellcheck source=/dev/null
        source "$DIR/modules/$module.sh"
        "module_${module//-/_}"   # 模块名里的连字符换成下划线（函数名规范）
    done

    echo
    ok "全部完成 ✔"
    echo
    echo "接下来："
    echo "  1) 【必须】注销并重新登录一次（GNOME 扩展首次安装需要）"
    echo "  2) 登录后运行  bash verify.sh  自检"
    echo "  3) 不满意就  bash restore.sh   一键还原"
    echo
    echo "备份目录：$BACKUP_DIR"
}

parse_args() {
    ASSUME_YES=false
    DRY_RUN=false
    FORCE=false
    MODULES=("${ALL_MODULES[@]}")

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y|--yes)   ASSUME_YES=true ;;
            -n|--dry-run) DRY_RUN=true ;;
            -f|--force) FORCE=true ;;
            --only)     IFS=',' read -r -a MODULES <<<"${2:-}"; shift ;;
            -h|--help)  usage; exit 0 ;;
            *) die "未知参数：$1（用 --help 看用法）" ;;
        esac
        shift
    done

    for module in "${MODULES[@]}"; do
        [[ -f "$DIR/modules/$module.sh" ]] || die "没有这个模块：$module"
    done
}

usage() {
    sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

main "$@"
