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

## 📦 包含的文件

| 文件 | 作用 |
|---|---|
| `apply-dsh-patches.sh` | 一键安装脚本（自动定位 DSH、校验版本、备份、应用补丁） |
| `dsh-host-apiproxy-lib-index.js.patch` | 后端：新增 `session.editLastPrompt` 端点 |
| `dsh-agent-loop-lib-index.js.patch` | 后端：turn() 时跳过同 id 的重复消息 |
| `dsh-client-connection-lib-client.js.patch` | 前端：客户端 RPC 调用面 + schema 镜像 |
| `dsh-client-runtime-lib-client.js.patch` | 前端：session.editLastPrompt + 折叠器感知 replace 阴影 |
| `dsh-client-ui-conversation-lib-client.js.rc7.patch` | 前端：输入历史 + 编辑按钮 UI（rc.7 版） |

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

## 🔄 如何更新到新版 DSH

官方升级版本会覆盖这些补丁（因为改的是 node_modules 编译产物）。升级流程：

```bash
npm install -g @deepseek-ai/dsh@<新版本>
# 若新版本与 rc.7 编译产物差异过大，补丁可能失效，需检查/修正
bash apply-dsh-patches.sh
```

> ⚠️ 若官方升级后补丁应用失败（`patch` 报错），说明新版本改了相应代码。需要基于新版本重新生成补丁，或到本仓库提 Issue 说明你遇到的版本。

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

## 📎 相关资源

- DeepSeek Harness 官方仓库：<https://github.com/deepseek-ai/deepseek-harness>
- DeepSeek Harness npm：`@deepseek-ai/dsh`

---

**维护**：cslht11 · 用于个人多设备同步 DSH 自定义增强。
