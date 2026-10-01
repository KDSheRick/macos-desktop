#!/usr/bin/env bash
# 热重载 GNOME Shell 用户主题（改完 gnome-shell.css 后不用注销即可生效）。
set -euo pipefail

CUR="$(dconf read /org/gnome/shell/extensions/user-theme/name | tr -d "'")"
if [ -z "$CUR" ]; then
  echo '未设置 user-theme，跳过'
  exit 0
fi

if [ "$CUR" = "MacTahoe-Dark" ]; then
  TMP="MacTahoe-Light"
else
  TMP="MacTahoe-Dark"
fi

dconf write /org/gnome/shell/extensions/user-theme/name "'$TMP'"
sleep 1
dconf write /org/gnome/shell/extensions/user-theme/name "'$CUR'"
echo "主题已重载：$CUR"
