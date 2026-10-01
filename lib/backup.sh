#!/usr/bin/env bash
# 备份与清单（manifest）
#
# 目录结构：
#   ~/macos-desktop-backup/<时间戳>/
#     ├── manifest.tsv        # 本次安装做过什么（restore.sh 靠它还原）
#     ├── dconf/<path>.conf   # 安装前的 dconf 快照
#     └── files/...           # 被修改过的原文件
#
# manifest 每行：类型 <TAB> 内容
#   dconf         <path>                设置快照（还原时 load 回去）
#   file_added    <path>                本次新增的文件/目录（还原时删除）
#   file_modified <path>                本次修改的文件（还原时用 files/ 里的副本覆盖）
#   file_backup   <相对路径>            备份副本（file_modified 引用）
#   ext_enabled   <uuid>                本次启用的扩展（还原时 disable）

backup_init() {
    BACKUP_PREFIX="$USER_HOME/macos-desktop-backup"
    BACKUP_DIR="$BACKUP_PREFIX/$(date +%Y%m%d-%H%M%S)"
    MANIFEST="$BACKUP_DIR/manifest.tsv"

    if $DRY_RUN; then
        info "备份目录（dry-run 不创建）：$BACKUP_DIR"
        return 0
    fi
    mkdir -p "$BACKUP_DIR/dconf" "$BACKUP_DIR/files"
    : > "$MANIFEST"
    ok "备份目录：$BACKUP_DIR"
}

manifest_add() {
    if $DRY_RUN; then return 0; fi
    printf '%s\t%s\n' "$1" "$2" >> "$MANIFEST"
}

# 记录某个 dconf 路径安装前的值
backup_dconf() {
    local path="$1"
    if $DRY_RUN; then return 0; fi
    local safe_name
    safe_name="$(echo "$path" | tr '/' '_')"
    dconf dump "$path" > "$BACKUP_DIR/dconf/${safe_name}.conf" 2>/dev/null || true
    manifest_add dconf "$path"
}

# 新增文件/目录（记录后由 restore 删除）
mark_added() {
    local path="$1"
    if $DRY_RUN; then return 0; fi
    [[ -e "$path" ]] || return 0
    manifest_add file_added "$path"
}

# 修改文件前先备份副本
backup_file() {
    local path="$1"
    [[ -e "$path" ]] || return 0
    if $DRY_RUN; then return 0; fi
    local rel
    rel="$(echo "${path#"$USER_HOME"/}" | tr '/' '_')"
    cp -a "$path" "$BACKUP_DIR/files/$rel" 2>/dev/null || true
    manifest_add file_backup "$rel"
    manifest_add file_modified "$path"
}

# 扩展启用记录
mark_ext_enabled() {
    manifest_add ext_enabled "$1"
}
