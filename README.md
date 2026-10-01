# macOS 风格桌面一键安装（Ubuntu + GNOME）

把 Ubuntu 变成 macOS 风格的桌面：**毛玻璃 + 底部 Dock + 深色主题 + 桌面贴纸 + 顶栏歌词 + 灵动岛**。
一条命令安装，一条命令还原。

```bash
git clone https://github.com/KDSheRick/macos-desktop.git
cd macos-desktop
bash install.sh          # 安装（会先列出将要做的事并确认）
```

装完**注销重新登录一次**（GNOME 扩展首次加载需要），然后：

```bash
bash verify.sh           # 自检：逐项对照作者机器
bash restore.sh          # 后悔了：一键还原到安装前
```

## 效果

| 组件 | 效果 |
| --- | --- |
| 主题 | MacTahoe-Dark（GTK + GNOME Shell，深色） |
| 图标 / 光标 | MacTahoe 图标 + macOS 风格光标 |
| Dock | 底部居中、自动隐藏、48px 图标、半透明、圆点运行指示 |
| 毛玻璃 | Blur my Shell：面板 / Dock / 概览 / 弹窗模糊，贴纸窗口实时模糊 |
| 快捷设置 | 追加「深色玻璃 + 投影」补丁（MacTahoe 原版几乎全透明） |
| 窗口按钮 | 关闭 / 最小化 / 最大化移到左侧（macOS 习惯） |
| 输入 | 触控板双指滚动、深色模式、蓝强调色 |
| 桌面贴纸 | 11 张毛玻璃系统监控贴纸（CPU / 内存 / 磁盘 / 网络 / 电池 / 温度 / 音乐 / 文件 / 进程 / API 用量） |
| 顶栏歌词 | 托盘区显示当前歌词（可单独开关） |
| 灵动岛 | 顶栏正中间的胶囊：悬停展开音乐 / 歌词 / 时钟 / API 用量，通知自动展开显示，滚动歌词 |

## 支持范围

**只支持和作者一致的环境**（不是通用工具）：

- Ubuntu（`ID=ubuntu`）
- GNOME Shell **50**
- **Wayland** 会话（Ubuntu 默认）
- 桌面组件：`ubuntu-dock`、`ubuntu-appindicators`（Ubuntu 自带并已启用）

其他发行版 / GNOME 版本会给出警告，**不保证效果**（可用 `--force` 强行继续）。

## 用法

```bash
bash install.sh                      # 一键安装
bash install.sh --dry-run            # 只打印将要做的事，不动系统
bash install.sh --only dock,blur     # 只装指定模块
bash install.sh --only theme --force # 强制重装主题
bash install.sh --yes                # 不交互（脚本化）

bash verify.sh                       # 安装后自检（只读）
bash restore.sh                      # 还原到最近一次安装前
bash restore.sh --from <备份目录>     # 指定备份
```

可用模块：`appearance`（外观设置）、`theme`（主题/图标/光标）、`dock`、`blur`、
`shell-css`（快捷设置玻璃补丁）、`apps`（贴纸 / 歌词）、`extensions`（GNOME 扩展）。

## 安全与还原

- **全部是用户级改动**：`~/.themes`、`~/.local/share/...`、`~/.config/autostart`、dconf 设置；
  不动 `/usr`、不动系统包
- 安装前会把涉及的 **dconf 快照 + 被修改文件** 备份到 `~/macos-desktop-backup/<时间戳>/`，
  并写一份 `manifest.tsv`（做过什么）
- `restore.sh` 按 manifest 逐条撤销：删除新增文件、还原被改文件、恢复 dconf、停用新增扩展
- 每个模块可独立重跑（幂等），不会重复累积

## 不包含的内容（版权原因）

| 内容 | 说明 |
| --- | --- |
| **SF Pro 字体** | 苹果专有字体，不能分发。自备后会自动启用；没有则保持系统默认字体 |
| **壁纸** | 保持你原来的壁纸（`install.sh` 不碰壁纸设置） |
| **主题 / 图标 / 光标** | 来自第三方 GPL 项目，安装时从官方仓库下载（首次安装需要网络） |

## 常见问题

**Q：装完没变化 / 岛没出现？**
注销重新登录一次。仍不行就看扩展状态：

```bash
gnome-extensions info lyrics-panel@loong      # 状态应为 ACTIVE
gsettings get org.gnome.shell disable-user-extensions   # 应为 false（true 会禁用所有第三方扩展）
```

**Q：快捷设置面板还是透明的？**
玻璃补丁写在主题 CSS 里；主题更新后会覆盖，重跑一次补丁即可：

```bash
bash install.sh --only shell-css
```

**Q：想调整 Dock / 模糊参数？**
用 GNOME 的「扩展」应用里的设置界面，或改 `assets/dconf/*.conf` 后重跑对应模块。

**Q：字体不一致？**
自行安装 SF Pro（或改用 Inter 等），然后：

```bash
gsettings set org.gnome.desktop.interface font-name 'SF Pro Display 11'
```

**Q：安装下载很慢 / 失败？**
主题与扩展都从 GitHub / extensions.gnome.org 下载；网络受限时先手动把主题放进
`~/.themes`、图标放进 `~/.local/share/icons`，再跑 `install.sh`（已存在的会跳过）。

## 目录结构

```
macos-desktop/
├── install.sh            # 一键入口
├── restore.sh            # 一键还原
├── verify.sh             # 自检
├── lib/                  # 公共库：日志 / 环境检查 / 备份清单
├── modules/              # 各模块（可单独跑）
│   ├── appearance.sh     # 深色模式 / 字体 / 窗口按钮 / 触控板
│   ├── theme.sh          # GTK 主题 / 图标 / 光标
│   ├── dock.sh           # Dock
│   ├── blur.sh           # 毛玻璃
│   ├── shell-css.sh      # 用户主题 + 快捷设置玻璃补丁
│   ├── apps.sh           # 桌面贴纸 / 顶栏歌词（克隆 desktop-stickers 并安装）
│   └── extensions.sh     # GNOME 扩展（user-theme / Blur my Shell / 灵动岛）
└── assets/
    ├── dconf/            # 各模块的设置片段
    ├── quick-settings-glass.css
    └── reload-shell-theme.sh
```

## 依赖的项目

- [desktop-stickers](https://github.com/KDSheRick/desktop-stickers)（MIT）——桌面贴纸、顶栏歌词、灵动岛扩展
- [MacTahoe-gtk-theme](https://github.com/vinceliuice/MacTahoe-gtk-theme) / [MacTahoe-icon-theme](https://github.com/vinceliuice/MacTahoe-icon-theme) / [WhiteSur-cursors](https://github.com/vinceliuice/WhiteSur-cursors)（GPL-3.0，安装时下载）
- [Blur my Shell](https://github.com/aunetx/blur-my-shell)（GPL-3.0，安装时下载）

## 许可

本项目脚本部分使用 MIT License。第三方主题 / 图标 / 光标 / 扩展遵循其各自许可（GPL-3.0）。
