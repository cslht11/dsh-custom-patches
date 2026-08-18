#!/bin/bash
# check-update.sh — 检查 DSH 官方是否有新版本，并评估本补丁集是否需要重新适配
#
# 用法: bash check-update.sh
# 说明:
#   1. 读取本地已装 DSH 版本
#   2. 查询 npm 官方最新版
#   3. 若官方有新版，提示需要检查/适配，并给出下一动作指引

set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

# 补丁集适配的目标版本（见 versions.md）
TARGET="0.1.0-rc.7"

# 1. 本地已装版本（通过全局 npm root 找到 DSH）
LOCAL=""
GLOBAL_ROOT=$(npm root -g 2>/dev/null || echo "")
DSH_PKG=""
for cand in "$GLOBAL_ROOT/@deepseek-ai/dsh/package.json" "$HOME/.local/lib/node_modules/@deepseek-ai/dsh/package.json"; do
  if [ -f "$cand" ]; then DSH_PKG="$cand"; break; fi
done
if [ -n "$DSH_PKG" ]; then
  LOCAL=$(node -e "console.log(require('$DSH_PKG').version)" 2>/dev/null)
fi
[ -z "$LOCAL" ] && LOCAL="(未找到本地 DSH)"
echo -e "${GREEN}本地已装 DSH：${NC}$LOCAL"

# 2. 官方最新版
LATEST=""
LATEST=$(npm view @deepseek-ai/dsh version 2>/dev/null || echo "")
if [ -z "$LATEST" ]; then
  echo -e "${RED}❌ 无法查询 npm 上的 @deepseek-ai/dsh 版本（网络或 npm 源问题）${NC}"
  exit 1
fi
echo -e "${YELLOW}官方最新版本：${NC}$LATEST"

# 3. 判断
echo ""
if [ "$LATEST" = "$TARGET" ]; then
  echo -e "${GREEN}✅ 官方最新版 = 补丁集适配版本，无需额外处理。${NC}"
  echo -e "   适配版本：${YELLOW}$TARGET${NC}"
elif [ -n "$LOCAL" ] && [ "$LATEST" = "$LOCAL" ]; then
  echo -e "${GREEN}✅ 本地与官方均为 $LATEST。${NC}"
else
  echo -e "${RED}⚠️  官方最新 $LATEST 与本补丁适配版本 $TARGET 不一致，需要处理：${NC}"
  echo ""
  echo "  1) 在本地升级官方到 $LATEST："
  echo "     npm install -g @deepseek-ai/dsh@$LATEST"
  echo ""
  echo "  2) 检查官方是否已内置我们的功能："
  echo "     grep -rl 'editLastPrompt' /path/to/@deepseek-ai/*/lib/"
  echo "     grep -rl 'recallHistory' /path/to/@deepseek-ai/*/lib/"
  echo ""
  echo "  3) 运行安装脚本尝试直接套补丁（若官方代码没大改则直接成功）："
  echo "     bash apply-dsh-patches.sh"
  echo ""
  echo "  4) 若失败，按 ADAPTING.md 重新适配，并更新 versions.md"
fi
echo ""
