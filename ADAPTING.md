# 适配官方新版本（ADAPTING Guide）

> 当官方发布新版本，导致本补丁集失效时，按本指南重新适配。
> 适用人群：维护者。

---

## 何时需要适配

运行 `bash install-dsh-custom.sh -y` 后，若日志出现：
```
❌ 应用失败: <某个文件>
  可能是补丁已应用或文件已被改动
```
说明官方新版本改了对应代码，旧的补丁 hunk 不匹配，需要重新生成。

---

## 适配流程（一次完整循环）

### 第 1 步：装好新版本官方包
```bash
# 查最新版
npm view @deepseek-ai/dsh version

# 装新版（可装全局，或用临时目录隔离，避免干扰工作环境）
npm install -g @deepseek-ai/dsh@<新版本>
```

### 第 2 步：确认官方是否已内置我们的功能
**推荐**直接用一键脚本（它内置了检测，会自动跳过官方已内置的补丁）：
```bash
bash install-dsh-custom.sh -y
```
脚本会逐条判断：目标文件已含功能标记 ⇒ 视为官方已内置 ⇒ 自动跳过；否则列入待应用。

若想手动确认，也可 grep 功能标记：
```bash
PLUGIN=<全局或临时 DSH 的 node_modules>/@deepseek-ai
grep -rl "editLastPrompt" $PLUGIN/*/lib/ 2>/dev/null || echo "编辑重发：官方未内置，需保留补丁"
grep -rl "recallHistory"  $PLUGIN/*/lib/ 2>/dev/null || echo "输入历史：官方未内置，需保留补丁"
```
> 若官方某功能已内置 ⇒ 从 `patches/` 删除对应补丁，更新脚本 `install-dsh-custom.sh` 与 `apply-dsh-patches.sh` 的 `FILES` 数组及 `versions.md`，就不用再适配它。

### 第 3 步：重新实现 / 重新生成补丁
对每个失效的插件文件逐一手动重新改一遍（把功能代码补到新版对应位置），然后生成补丁：
```bash
# 假设你又在 lib/client.js 里改好了功能，且保留原始备份 client.js.bak
cd <到该插件目录>
diff -u lib/client.js.bak lib/client.js > /path/to/dsh-custom-patches/patches/client-ui-conversation/dsh-client-ui-conversation-lib-client.js.<新版本>.patch
```

> **技巧**：新版通常只是少数几行上下文变了。可先看旧补丁哪个 hunk 失败（`patch` 会输出 `Hunk #N failed`），只修正那一处，其余沿用。

### 第 4 步：更新脚本与追踪表
- 把新补丁文件名更新到 `install-dsh-custom.sh` 与 `apply-dsh-patches.sh` 的 `FILES` 数组（两者都改，保持一致）
- 在 `versions.md` 追加新版本一行
- 提交：
```bash
cd dsh-custom-patches
git add -A
git commit -m "适配官方 vX.Y.Z"
git push
```

### 第 5 步：验证
在其他设备 / 干净环境跑一遍 `bash install-dsh-custom.sh -y` 确认成功，再重启 `dsh web` 实测功能。

---

## 常见问题

| 现象 | 处理 |
|---|---|
| 某个补丁 1 个 hunk 失败，其余成功 | 手动把缺失的几行补到新版对应位置，重新生成该文件补丁 |
| 整个补丁全失败 | 官方该文件大改，需要对照功能逻辑重写 |
| 官方内置了某功能 | 删除该功能对应补丁，更新脚本和 versions.md |
| 不确定官方是否内置 | 用 `versions.md` 里的 grep 命令确认 |

---

## 保持补丁最小化

- 每次只改**必要几处**，避免为了"更像官方"而无关改动。
- 补丁尽量小 ⇒ 与新版的冲突点少，适配容易。
- 每个功能标记清晰（`editLastPrompt` 等），便于 grep 定位和排查。
