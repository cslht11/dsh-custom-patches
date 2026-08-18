# DSH 自定义增强补丁（Custom Enhancements for DeepSeek Harness）

> 为 [DeepSeek Harness (DSH)](https://github.com/deepseek-ai/deepseek-harness) Web GUI 添加两个官方暂未提供的实用功能：
> **① 输入框 ↑/↓ 键发送历史** 与 **② 编辑最后一条消息并重新生成（Codex 风格）**。
>
> 适配版本：**`@deepseek-ai/dsh@0.1.0-rc.7`**

---

## ✨ 功能简介

### 1. 输入框上下键历史（类似终端）
- 在输入框按 **↑** 调出上一条发送过的消息，继续按 ↑ 逐条往前翻；按 **↓** 往回翻
- 编辑输入文字时，历史浏览位置自动重置
- 兼容中文输入法（拼音选词时不会误触）、多行文本（光标在首/末行才触发）、连续相同内容去重

### 2. 编辑最后一条消息并重新生成（Codex 风格）
- 将鼠标移到**最后一条用户消息**上，会看到一个 **✏️ 编辑**按钮
- 点击后消息变成可编辑文本框（预填原文）
- 修改后点击 **"保存并重新生成"**：新文本替换原文，**丢弃它之后的所有 AI 回复/工具调用**，AI 用新内容重新生成
- 更早的消息只保留复制，不可编辑；AI 正在工作时不允许编辑（防冲突）
- 点击 **取消** 恢复原样

**机制说明**：编辑通过 DSH 会话层的 **surface replace**（append-only 日志 + 阴影替换）实现——历史记录保留，但模型与界面只看替换后的新序列。

---

## 📦 项目结构

```
dsh-custom-patches/
├── README.md            # 本文件
├── apply-dsh-patches.sh # 一键安装脚本（自动定位、校验版本、备份、应用）
├── check-update.sh      # 检测官方是否有新版本，评估是否需要重新适配
├── versions.md          # 版本追踪表（官方版本 × 补丁适用性 × 官方是否内置功能）
├── ADAPTING.md          # 适配官方新版的操作手册（面向维护者）
└── patches/             # 补丁文件（按插件包分目录）
    ├── host-apiproxy/            → 新增 session.editLastPrompt 端点
    ├── agent-loop/               → turn() 跳过同 id 重复消息
    ├── client-connection/        → 客户端 RPC 调用面 + schema 镜像
    ├── client-runtime/           → editLastPrompt + 折叠器感知 replace 阴影
    └── client-ui-conversation/   → 输入历史 + 编辑按钮 UI
```

> 这 5 个补丁对应的 5 个 npm 插件包：
> `dsh-host-apiproxy` · `dsh-agent-loop` · `dsh-client-connection` · `dsh-client-runtime` · `dsh-client-ui-conversation`

---

## 🚀 安装步骤（在其他设备上）

### 前提
- 已安装 Node.js
- 已全局安装 **`@deepseek-ai/dsh@0.1.0-rc.7`**（版本必须匹配）

### 第 1 步：安装 / 确认版本
```bash
npm install -g @deepseek-ai/dsh@0.1.0-rc.7
dsh --version   # 确认是 0.1.0-rc.7
```

### 第 2 步：克隆本仓库
```bash
git clone git@github.com-cslht11:cslht11/dsh-custom-patches.git
# 或 HTTPS
git clone https://github.com/cslht11/dsh-custom-patches.git
cd dsh-custom-patches
```

### 第 3 步：运行安装脚本
```bash
bash apply-dsh-patches.sh
```
脚本会自动：
1. 定位 DSH 安装目录
2. 校验版本是否为 `0.1.0-rc.7`（不匹配会拒绝并提示先升级）
3. 对 5 个插件文件逐一备份（生成 `.bak`）并应用补丁
4. 提示重启

### 第 4 步：重启 DSH
```bash
kill $(pgrep -f 'dsh web') 2>/dev/null
dsh web
```

### 第 5 步：刷新页面
浏览器打开 DSH Web，**硬刷新**（`Cmd+Shift+R`）：
- 输入框按 ↑ 即可翻历史
- 最后一条用户消息 hover 出现 ✏️ 编辑按钮

---

## 🔄 如何跟进官方更新

官方升级版本会覆盖这些补丁（因为改的是 node_modules 编译产物）。推荐用配套工具跟进：

```bash
# 1) 检测官方是否有新版（自动对比本地/最新/适配版本）
bash check-update.sh

# 2) 升级官方
npm install -g @deepseek-ai/dsh@<新版本>

# 3) 重新应用补丁（若新版代码没大变则直接成功）
bash apply-dsh-patches.sh
```

- **官方是否已内置我们的功能？** 看 [`versions.md`](versions.md) 的检测方法（grep 功能标记）。若官方已内置，则删除对应补丁、更新脚本即可，无需再适配。
- **补丁失效了？** 按 [`ADAPTING.md`](ADAPTING.md) 的操作手册重新适配，并在 `versions.md` 追加新版本的一行。

> ⚠️ 若官方升级后补丁应用失败（`patch` 报错），说明新版本改了相应代码，需要按 `ADAPTING.md` 重新适配。

---

## ↩️ 如何恢复原版（卸载补丁）

```bash
# 用安装脚本自动生成的 .bak 备份恢复
PLUGIN="$HOME/.local/lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai"
for e in \
  dsh-host-apiproxy/lib/index.js \
  dsh-agent-loop/lib/index.js \
  dsh-client-connection/lib/client.js \
  dsh-client-runtime/lib/client.js \
  dsh-client-ui-conversation/lib/client.js; do
  cp "$PLUGIN/$e.bak" "$PLUGIN/$e"
done
```

---

## ⚠️ 重要说明

1. **本补丁集不是官方插件**，而是直接修补 `node_modules` 编译产物实现。任何 `npm` 重装 / 升级 DSH 都会覆盖，需重新应用。
2. **只适配 `0.1.0-rc.7`**。不同小版本之间的编译产物可能有差异，补丁可能不适用于其他版本。
3. 官方仓库 [CONTRIBUTING.md](https://github.com/deepseek-ai/deepseek-harness/blob/master/CONTRIBUTING.md) 明确说明**暂不接受外部 PR**，因此这两个功能只能通过本补丁方式使用，无法通过官方合并获得。
4. 如遇问题，先确认 DSH 版本是否为 `0.1.0-rc.7`，再确认补丁是否有 `.bak` 备份可回滚。

---

## 🛠 如何为这个仓库添加新功能（维护者）

本仓库用于把 DSH 的自定义增强**以编译产物补丁**的形式备份与分发。新增功能流程：

1. 在本地 DSH 的 `node_modules/@deepseek-ai/<包>/lib/` 里直接改代码（并保留 `*.bak` 原始备份）。
2. 用 `diff` 生成补丁文件：
   ```bash
   diff -u <包>/lib/<文件>.bak <包>/lib/<文件> > <名>.patch
   ```
3. 补丁文件命名用相对于插件包的路径，如 `dsh-client-ui-conversation-lib-client.js.patch`（含 `rc.7` 时加 `.rc7`）。
4. 更新 `apply-dsh-patches.sh` 里的 `FILES` 数组，加入新补丁的映射。
5. 提交并推送：
   ```bash
   git add -A
   git commit -m "feat: 添加 <功能说明>"
   git push origin main
   ```

> 提交时仓库身份已固定为 `cslht11 <cslht11@163.com>`，推送走 gh 活跃账号 cslht11。

---

## 📎 相关资源

- DeepSeek Harness 官方仓库：<https://github.com/deepseek-ai/deepseek-harness>
- DeepSeek Harness npm：`@deepseek-ai/dsh`
- 本仓库：<https://github.com/cslht11/dsh-custom-patches>

---

**维护**：cslht11 · 用于个人多设备同步 DSH 自定义增强，也欢迎有需要的朋友直接使用本补丁集。
