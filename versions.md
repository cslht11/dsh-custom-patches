# 版本追踪表（Version Tracking）

记录每个官方版本下，本补丁集是否可用，以及官方是否已内置我们的功能。

| 官方版本 | 补丁可用？ | 官方内置「输入历史」？ | 官方内置「编辑重发」？ | 备注 |
|---|---|---|---|---|
| 0.1.0-rc.6 | ✅ 全部可用 | ❌ | ❌ | 最初适配（历史基准） |
| 0.1.0-rc.7 | ✅ 全部可用（ui 需用 `.rc7` 版） | ❌ | ❌ |  |
| 0.1.0-rc.8 | ✅ 全部可用（ui 用 `.rc8` 版） | ❌ | ❌ |  |
| 0.1.1-rc.2 | ✅ 全部可用（ui 用 `.rc2` 版） | ❌ | ❌ | **当前基准** |

---

## 检测方法

### 1. 官方是否内置了我们的功能
在官方源码/新版 npm 包里搜索功能标记：
```bash
# 编辑重发
grep -rl "editLastPrompt" node_modules/@deepseek-ai/*/lib/ 2>/dev/null
# 输入历史
grep -rl "recallHistory\|sendHistory\|historyIndexRef" node_modules/@deepseek-ai/*/lib/ 2>/dev/null
```
若无输出 ⇒ 官方未内置，需要保留/继续适配我们的补丁。

### 2. 补丁是否仍适配新版
用 dry-run 测试是否仍能套上：
```bash
# 对每个补丁，切换到新版目标文件所在目录后：
patch --dry-run -N -p1 < 补丁文件.patch
```
- 全部通过 ⇒ 补丁沿用。
- 有 hunk 失败 ⇒ 需要重新适配（见 `ADAPTING.md`）。

---

## 功能标记对照

| 功能 | 核心标记（grep 用） | 涉及插件 |
|---|---|---|
| 编辑重发 | `editLastPrompt` | host-apiproxy / agent-loop / client-connection / client-runtime / ui-conversation |
| 输入历史 | `recallHistory` `sendHistory` `historyIndexRef` | ui-conversation |
