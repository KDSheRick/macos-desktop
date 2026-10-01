#!/usr/bin/env bash
# 一键还原：按安装时生成的 manifest 撤销所有改动
#
#   bash restore.sh                 # 用最近一次安装的备份
#   bash restore.sh --from <目录>   # 指定备份目录
#   bash restore.sh --dry-run       # 只打印将要做的事
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$DIR/lib/common.sh"

DRY_RUN=false
BACKUP_DIR=""

usage() { sed -n '2,8p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run) DRY_RUN=true ;;
            --from) BACKUP_DIR="${2:-}"; shift ;;
            -h|--help) usage; exit 0 ;;
            *) die "未知参数：$1" ;;
        esac
        shift
    done

    if [[ -z "$BACKUP_DIR" ]]; then
        BACKUP_DIR="$(ls -1d "$USER_HOME"/macos-desktop-backup/*/ 2>/dev/null | sort | tail -1 || true)"
    fi
    [[ -n "$BACKUP_DIR" && -f "$BACKUP_DIR/manifest.tsv" ]] || die "找不到备份清单（用 --from 指定备份目录）"

    local manifest="$BACKUP_DIR/manifest.tsv"
    echo "${C_BOLD}从备份还原：$BACKUP_DIR${C_RESET}"
    echo

    # ---- 1) 撤销扩展启用 ----
    while read -r kind value; do
        [[ "$kind" == "ext_enabled" ]] || continue
        info "  停用扩展 $value"
        run gnome-extensions disable "$value" 2>/dev/null || true
    done < "$manifest"

    # ---- 2) 删除本次新增的文件 ----
    while read -r kind value; do
        [[ "$kind" == "file_added" ]] || continue
        [[ -e "$value" ]] || continue
        info "  删除新增：$value"
        run rm -rf "$value"
    done < "$manifest"

    # ---- 3) 还原被修改的文件 ----
    while read -r kind value; do
        [[ "$kind" == "file_modified" ]] || continue
        local rel
        rel="$(echo "${value#"$USER_HOME"/}" | tr '/' '_')"
        local copy="$BACKUP_DIR/files/$rel"
        if [[ -e "$copy" ]]; then
            info "  还原文件：$value"
            run mkdir -p "$(dirname "$value")"
            run cp -a "$copy" "$value"
        fi
    done < "$manifest"

    # ---- 4) 还原 dconf ----
    while read -r kind value; do
        [[ "$kind" == "dconf" ]] || continue
        local safe
        safe="$(echo "$value" | tr '/' '_')"
        local snap="$BACKUP_DIR/dconf/${safe}.conf"
        if [[ -f "$snap" ]]; then
            info "  还原设置：$value"
            run_sh "dconf load '$value' < '$snap'"
        fi
    done < "$manifest"

    echo
    ok "还原完成 ✔"
    echo "建议注销并重新登录一次，让扩展与主题状态彻底回到安装前。"
}

main "$@"
