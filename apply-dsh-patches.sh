#!/bin/bash
# DSH 自定义补丁安装脚本（适配 @deepseek-ai/dsh 0.1.1-rc.2）
# 在另一台安装好 DSH rc.2 的设备上运行此脚本即可应用所有自定义功能。
# 用法: bash apply-dsh-patches.sh

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# 目标 DSH 版本（本补丁集适配 rc.2）
EXPECT_VERSION="0.1.1-rc.2"

# 补丁与目标文件映射（相对 @deepseek-ai 插件目录）
# 格式: "相对插件路径|补丁在仓库中的相对路径"
FILES=(
  "dsh-host-apiproxy/lib/index.js|patches/host-apiproxy/dsh-host-apiproxy-lib-index.js.patch"
  "dsh-agent-loop/lib/index.js|patches/agent-loop/dsh-agent-loop-lib-index.js.patch"
  "dsh-client-connection/lib/client.js|patches/client-connection/dsh-client-connection-lib-client.js.patch"
  "dsh-client-runtime/lib/client.js|patches/client-runtime/dsh-client-runtime-lib-client.js.patch"
  "dsh-client-ui-conversation/lib/client.js|patches/client-ui-conversation/dsh-client-ui-conversation-lib-client.js.rc2.patch"
)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 1. 定位 DSH 安装目录
DSH_DIR=$(node -e "try{console.log(require.resolve('@deepseek-ai/dsh/package.json').replace('/package.json',''))}catch(e){console.log('')}" 2>/dev/null)
if [ -z "$DSH_DIR" ]; then
  DSH_DIR=$(find /usr/local/lib/node_modules "$HOME/.local/lib/node_modules" -name "dsh" -path "*/@deepseek-ai/*" -type d 2>/dev/null | head -1)
fi
if [ -z "$DSH_DIR" ]; then
  echo -e "${RED}❌ 未找到 DSH 安装目录，请先安装 @deepseek-ai/dsh@$EXPECT_VERSION${NC}"
  exit 1
fi
echo -e "${GREEN}✅ 找到 DSH: $DSH_DIR${NC}"

# 2. 校验版本
VERSION=$(node -e "console.log(require('$DSH_DIR/package.json').version)" 2>/dev/null)
echo -e "   当前版本: ${YELLOW}$VERSION${NC}"
if [ "$VERSION" != "$EXPECT_VERSION" ]; then
  echo -e "${RED}❌ 版本不匹配：本补丁集适配 $EXPECT_VERSION，当前是 $VERSION${NC}"
  echo -e "${RED}   请先升级：npm install -g @deepseek-ai/dsh@$EXPECT_VERSION${NC}"
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
echo -e "${GREEN}  补丁应用完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "下一步:"
echo -e "  1. ${YELLOW}重启 DSH: kill $(pgrep -f 'dsh web') 2>/dev/null; dsh web${NC}"
echo -e "  2. 刷新浏览器页面使用新的功能"
echo ""
echo -e "如需恢复原版（仅当前设备）:"
echo -e "  ${YELLOW}for e in dsh-host-apiproxy/lib/index.js dsh-agent-loop/lib/index.js dsh-client-connection/lib/client.js dsh-client-runtime/lib/client.js dsh-client-ui-conversation/lib/client.js; do cp \"$PLUGIN_ROOT/\$e.bak\" \"$PLUGIN_ROOT/\$e\"; done${NC}"
