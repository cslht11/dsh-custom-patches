#!/bin/bash
# DSH 自定义补丁安装脚本（适配 @deepseek-ai/dsh）
# 用法:
#   bash apply-dsh-patches.sh                # 默认适配最新版本 0.1.1-rc.2
#   bash apply-dsh-patches.sh 0.1.0-rc.8     # 老版本用户：指定自己的 DSH 版本
#   bash apply-dsh-patches.sh 0.1.0-rc.7
#
# 支持版本见 versions.md：rc.7 / rc.8 / 0.1.1-rc.2 均有独立补丁文件；
# rc.6 及更早没有单独保存（本仓库自 rc.7 起发布），需升级官方后再用。

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# 目标 DSH 版本：默认适配最新，也可通过第一个参数指定老版本
DEFAULT_VERSION="0.1.1-rc.2"
TARGET_VERSION="${1:-$DEFAULT_VERSION}"

# ===== 版本 → ui-conversation 补丁后缀 映射 =====
# 官方主要在 ui-conversation 包里调整界面布局，故该补丁按版本区分
# （.rc7.patch / .rc8.patch / .rc2.patch，均保留在本仓库 patches/ 下）。
# 其余 4 个补丁（host-apiproxy / agent-loop / client-runtime /
# client-connection）在 rc.7 → rc.8 → rc.2 间内容一致，跨版本通用。
case "$TARGET_VERSION" in
  0.1.1-rc.2)  UI_SUFFIX="rc2" ;;
  0.1.0-rc.8)  UI_SUFFIX="rc8" ;;
  0.1.0-rc.7)  UI_SUFFIX="rc7" ;;
  0.1.0-rc.6)
    echo -e "${RED}❌ 0.1.0-rc.6 及更早没有单独保存补丁文件（本仓库自 rc.7 起发布）。${NC}"
    echo -e "   建议升级官方：npm install -g @deepseek-ai/dsh@0.1.1-rc.2，再重新运行本脚本。"
    exit 1
    ;;
  *)
    echo -e "${RED}❌ 不支持的版本: ${YELLOW}$TARGET_VERSION${NC}"
    echo -e "   支持的版本: 0.1.1-rc.2（默认）/ 0.1.0-rc.8 / 0.1.0-rc.7"
    exit 1
    ;;
esac

# 补丁与目标文件映射（相对 @deepseek-ai 插件目录）
# 格式: "相对插件路径|补丁在仓库中的相对路径"
FILES=(
  "dsh-host-apiproxy/lib/index.js|patches/host-apiproxy/dsh-host-apiproxy-lib-index.js.patch"
  "dsh-agent-loop/lib/index.js|patches/agent-loop/dsh-agent-loop-lib-index.js.patch"
  "dsh-client-connection/lib/client.js|patches/client-connection/dsh-client-connection-lib-client.js.patch"
  "dsh-client-runtime/lib/client.js|patches/client-runtime/dsh-client-runtime-lib-client.js.patch"
  "dsh-client-ui-conversation/lib/client.js|patches/client-ui-conversation/dsh-client-ui-conversation-lib-client.js.${UI_SUFFIX}.patch"
)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 1. 定位 DSH 安装目录
DSH_DIR=$(node -e "try{console.log(require.resolve('@deepseek-ai/dsh/package.json').replace('/package.json',''))}catch(e){console.log('')}" 2>/dev/null)
if [ -z "$DSH_DIR" ]; then
  DSH_DIR=$(find /usr/local/lib/node_modules "$HOME/.local/lib/node_modules" -name "dsh" -path "*/@deepseek-ai/*" -type d 2>/dev/null | head -1)
fi
if [ -z "$DSH_DIR" ]; then
  echo -e "${RED}❌ 未找到 DSH 安装目录，请先安装 @deepseek-ai/dsh@$TARGET_VERSION${NC}"
  exit 1
fi
echo -e "${GREEN}✅ 找到 DSH: $DSH_DIR${NC}"

# 2. 校验版本
VERSION=$(node -e "console.log(require('$DSH_DIR/package.json').version)" 2>/dev/null)
echo -e "   当前版本: ${YELLOW}$VERSION${NC}（补丁目标: ${YELLOW}$TARGET_VERSION${NC}）"
if [ "$VERSION" != "$TARGET_VERSION" ]; then
  echo -e "${RED}❌ 版本不匹配：本补丁集按 $TARGET_VERSION 适配，当前是 $VERSION${NC}"
  echo -e "   两种处理方式（任选其一）："
  echo -e "     a) 老版本用户：加上你的版本号重试，例如 ${YELLOW}bash apply-dsh-patches.sh $VERSION${NC}"
  echo -e "     b) 想用最新版：升级 ${YELLOW}npm install -g @deepseek-ai/dsh@$TARGET_VERSION${NC} 后重试"
  exit 1
fi

# 3. 检查补丁文件齐全
ALL_OK=true
for entry in "${FILES[@]}"; do
  patch_file="${entry#*|}"
  if [ -f "$SCRIPT_DIR/$patch_file" ]; then
    echo -e "  ${GREEN}✅ 找到补丁: $patch_file${NC}"
  else
    echo -e "  ${RED}❌ 缺失补丁: $patch_file${NC}"
    ALL_OK=false
  fi
done
[ "$ALL_OK" = false ] && { echo -e "\n${RED}请将补丁文件与脚本放在同一目录后重试。${NC}"; exit 1; }

# 4. 逐条备份并应用
echo ""
echo -e "${YELLOW}开始备份并应用补丁…${NC}"
PLUGIN_ROOT="$DSH_DIR/node_modules/@deepseek-ai"
for entry in "${FILES[@]}"; do
  rel_path="${entry%%|*}"; patch_file="${entry#*|}"
  full_path="$PLUGIN_ROOT/$rel_path"

  if [ ! -f "$full_path" ]; then
    echo -e "  ${YELLOW}⚠️  跳过（目标不存在）: $rel_path${NC}"
    continue
  fi

  # 备份（首次）
  if [ ! -f "$full_path.bak" ]; then
    cp "$full_path" "$full_path.bak"
    echo -e "  ${GREEN}✓${NC} 已备份: $rel_path.bak"
  fi

  # 应用
  if patch --dry-run -N -p1 "$full_path" < "$SCRIPT_DIR/$patch_file" >/dev/null 2>&1; then
    patch -N -p1 "$full_path" < "$SCRIPT_DIR/$patch_file" >/dev/null 2>&1
    echo -e "  ${GREEN}✅ 已应用: $rel_path${NC}"
  else
    echo -e "  ${RED}❌ 应用失败: $rel_path${NC}"
    echo -e "    可能是补丁已应用或文件已被改动。可尝试：cp '$full_path.bak' '$full_path' 后重跑。"
  fi
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  补丁应用完成（适配 $TARGET_VERSION）！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "下一步:"
echo -e "  1. ${YELLOW}重启 DSH: kill $(pgrep -f 'dsh web') 2>/dev/null; dsh web${NC}"
echo -e "  2. 刷新浏览器页面使用新的功能"
echo ""
echo -e "如需恢复原版（仅当前设备）:"
echo -e "  ${YELLOW}for e in dsh-host-apiproxy/lib/index.js dsh-agent-loop/lib/index.js dsh-client-connection/lib/client.js dsh-client-runtime/lib/client.js dsh-client-ui-conversation/lib/client.js; do cp \"$PLUGIN_ROOT/\$e.bak\" \"$PLUGIN_ROOT/\$e\"; done${NC}"