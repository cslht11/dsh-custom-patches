# DSH 自定义增强补丁（Custom Enhancements for DeepSeek Harness）

为 [DeepSeek Harness (DSH)](https://github.com/deepseek-ai/deepseek-harness) Web GUI 添加两个官方暂未提供的实用功能：
**① 输入框 ↑/↓ 键发送历史** 与 **② 编辑最后一条消息并重新生成（Codex 风格）**。

- 适配版本：**`@deepseek-ai/dsh@0.1.0-rc.7`**
- 许可证：**MIT**（详见 [LICENSE](LICENSE)）
- 维护：cslht11（<heitieya@163.com>）

> **这是什么 / 不是什么**：这是一套**编译产物补丁**，不是官方插件，也不是源码 fork。
> 它通过 `diff`/`patch` 直接修补 DSH 已装好的 npm 包文件（`node_modules` 里的编译 JS），
> 给 DSH 加上官方还没有的两个功能。**任何 npm 重装 / 升级 DSH 都会覆盖这些补丁，需重新应用。**

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

## ⚠️ 平台与前置要求（先看这里）

安装脚本是用 **bash 编写、依赖 Unix 命令行工具** 的，因此：

| 平台 | 是否支持 | 说明 |
|---|---|---|
| **macOS** | ✅ 原生支持 | 自带的 `bash`/`patch`/`pgrep` 即可 |
| **Linux** | ✅ 原生支持 | 自带 `patch`；部分精简发行版需 `sudo apt install patch` |
| **Windows** | ⚠️ 需要额外准备 | 需安装 **Git Bash**（自带 bash 与 git），并准备 **GNU patch** 与 **pgrep**（例：经 `choco install patch`，或使用 MSYS2/Git for Windows 配套工具） |

**统一前置条件**（任意平台）：
- 已安装 **Node.js**（含 `npm`）
- 已用 npm **全局安装 `@deepseek-ai/dsh@0.1.0-rc.7`**（版本必须匹配，否则脚本会拒绝）

> 对 Windows 用户：若你的 DSH 运行在 WSL / 云主机 / 服务器（Linux）上，走 Linux 支持即可，无需在 Windows 本机装补丁。

---

## 🚀 快速开始（各平台通用）

只需要三步。**推荐用 HTTPS 克隆**（无需配置 SSH key）。

```bash
# 1) 安装匹配版本的 DSH（已装且版本正确可跳过）
npm install -g @deepseek-ai/dsh@0.1.0-rc.7
dsh --version          # 应输出 0.1.0-rc.7

# 2) 克隆本仓库（HTTPS，对所有人可用）
git clone https://github.com/cslht11/dsh-custom-patches.git
cd dsh-custom-patches

# 3) 一键安装（-y 跳过交互确认；脚本会自动定位 DSH、校验版本、检测官方是否已内置、备份并应用）
bash install-dsh-custom.sh -y

# 4) 重启并验证
kill $(pgrep -f 'dsh web') 2>/dev/null && sleep 1; dsh web
```

然后**硬刷新**浏览器页面（`Cmd+Shift+R` / `Ctrl+Shift+R`）：
- 输入框按 **↑** 即可翻历史
- 最后一条用户消息 **hover（鼠标悬停）** 出现 **✏️ 编辑** 按钮

> 也可以把本仓库链接 `https://github.com/cslht11/dsh-custom-patches` 直接发给你的 AI 助手，
> 让它按本文档的「快速开始」步骤在你的机器上完成配置；文档中的命令均可直接执行。

---

## 🛠 分步说明（想了解细节再看）

### 第 1 步：确认 DSH 版本
```bash
npm install -g @deepseek-ai/dsh@0.1.0-rc.7   # 装到匹配版本
dsh --version                                 # 确认是 0.1.0-rc.7
```

### 第 2 步：克隆仓库
HTTPS（推荐，任何机器可用）：
```bash
git clone https://github.com/cslht11/dsh-custom-patches.git
cd dsh-custom-patches
```
SSH（可选，需你已在自己机器上配好 GitHub SSH key）：
```bash
git clone git@github.com:cslht11/dsh-custom-patches.git
cd dsh-custom-patches
```

### 第 3 步：运行安装脚本
推荐用带诊断与内置检测的**一键脚本**：
```bash
bash install-dsh-custom.sh -y
```
脚本会自动：
1. 定位 DSH 安装目录（同时探测系统级与用户级全局路径）
2. 读取本地版本并查询 npm 官方最新版，给出版本诊断
3. **校验版本**是否为 `0.1.0-rc.7`（不匹配会拒绝并提示先升级）
4. **检测官方是否已内置功能**——若目标文件已含功能标记（例如官方新版把这些功能收编了），自动跳过对应补丁
5. 对需要应用的补丁**逐一备份（生成 `.bak`）并应用**
6. 汇总报告 + 提示重启

> 备选：`bash apply-dsh-patches.sh`（功能相同，但没有版本诊断与内置检测；两者等效地应用同一套补丁，任选其一即可）。

### 第 4 步：重启 DSH
```bash
kill $(pgrep -f 'dsh web') 2>/dev/null; sleep 1; dsh web
```

### 第 5 步：验收（确认安装成功）
刷新页面后，检查以下**可观察信号**，全部满足即安装成功：
- [x] 输入框按 **↑** 能翻出上一条消息
- [x] 鼠标悬停到**最后一条用户消息**上出现 **✏️ 编辑** 按钮
- [x] 点击编辑 → 改内容 → 「保存并重新生成」能替换并重新生成

> 也可用脚本自诊断：再次运行 `bash install-dsh-custom.sh -y`，若输出 *"All features already present (built-in or applied). Nothing to do."* 即表示所有功能已就位。

---

## ↩️ 如何恢复原版（卸载补丁）

安装时脚本已为每个被改文件生成 `.bak` 备份。恢复只需把这些备份拷贝回去（**路径用 `npm root -g` 动态获取，兼容任意全局安装方式**）：

```bash
PLUGIN="$(npm root -g)/@deepseek-ai/dsh/node_modules/@deepseek-ai"
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

## 🔄 如何跟进官方更新

官方升级会覆盖这些补丁（因为改的是 node_modules 编译产物）。推荐用配套工具跟进：

```bash
# 1) 检测官方是否有新版（自动对比本地/最新/适配版本）
bash check-update.sh

# 2) 升级官方
npm install -g @deepseek-ai/dsh@<新版本>

# 3) 重新应用（含内置检测；若官方新版没大改则直接成功）
bash install-dsh-custom.sh -y
```

- **官方是否已内置我们的功能？** 一键脚本会自动检测并跳过已内置的补丁；也可手动用 [`versions.md`](versions.md) 里的 grep 方法确认。
- **补丁失效了？** 按 [`ADAPTING.md`](ADAPTING.md) 的操作手册重新适配，并在 `versions.md` 追加新版本一行。

> ⚠️ 若升级后 `patch` 报错，说明新版改了相应代码，需要按 `ADAPTING.md` 重新适配。

---

## 📦 项目结构

```
dsh-custom-patches/
├── README.md               # 本文件
├── install-dsh-custom.sh   # 【推荐】一键安装（诊断版本 + 检测官方是否内置 + 备份 + 应用）
├── apply-dsh-patches.sh    # 基础安装脚本（自动定位、校验版本、备份、应用）
├── check-update.sh         # 检测官方是否有新版本，评估是否需要重新适配
├── versions.md             # 版本追踪表（官方版本 × 补丁适用性 × 官方是否内置功能）
├── ADAPTING.md             # 适配官方新版的操作手册（面向维护者）
├── LICENSE                 # MIT 许可证
└── patches/                # 补丁文件（按插件包分目录）
    ├── host-apiproxy/            → 新增 session.editLastPrompt 端点
    ├── agent-loop/               → turn() 跳过同 id 重复消息
    ├── client-connection/        → 客户端 RPC 调用面 + schema 镜像
    ├── client-runtime/           → editLastPrompt + 折叠器感知 replace 阴影
    └── client-ui-conversation/   → 输入历史 + 编辑按钮 UI
```

> 这 5 个补丁对应 5 个 npm 插件包：`dsh-host-apiproxy` · `dsh-agent-loop` · `dsh-client-connection` · `dsh-client-runtime` · `dsh-client-ui-conversation`

---

## 🤔 我可以改它吗？如何贡献 / 联系

**能，欢迎。** 本项目以 **MIT** 授权，你可以自由使用、修改、再分发。

需要先理解它的形态，再决定怎么"改"：

- **想直接用这套功能**：clone → `bash install-dsh-custom.sh -y` 即可（见「快速开始」）。
- **想给它加自己的新功能**：本项目是**补丁集**，二次开发的方式是——在你自己 DSH 的 `node_modules/@deepseek-ai/<包>/lib/` 里改代码，再用 `diff` 生成补丁加入本仓库的 `patches/`。完整流程见[「维护者如何新增功能」](#-维护者如何新增功能)。
- **想从源码层面改 DSH 本身**：那是另一条路——fork DeepSeek Harness 官方源码再改。请注意官方 [CONTRIBUTING.md](https://github.com/deepseek-ai/deepseek-harness/blob/master/CONTRIBUTING.md) 明确**暂不接受外部 PR**，所以这两个功能目前只能通过本补丁方式获得。

**想反馈问题 / 提建议 / 问问题**：在仓库的 **Issues** 里新建即可（已开启），或发邮件到 <heitieya@163.com>。

---

## 🛠 维护者如何新增功能

> 适用人群：本仓库维护者（或想贡献新补丁的人）。

1. 在本地 DSH 的 `node_modules/@deepseek-ai/<包>/lib/` 里直接改代码（并保留 `*.bak` 原始备份）。
2. 用 `diff` 生成补丁文件：
   ```bash
   diff -u <包>/lib/<文件>.bak <包>/lib/<文件> > <名>.patch
   ```
3. 补丁文件命名用相对于插件包的路径，如 `dsh-client-ui-conversation-lib-client.js.patch`（含版本号时加后缀，如 `.rc7`）。
4. 更新脚本里的映射数组（`install-dsh-custom.sh` 与 `apply-dsh-patches.sh` 的 `FILES`），加入新补丁。
5. 提交并推送：
   ```bash
   git add -A
   git commit -m "feat: 添加 <功能说明>"
   git push origin main
   ```

> 提交时仓库身份已固定为 `cslht11 <heitieya@163.com>`，推送走 gh 活跃账号 cslht11。

---

## 📄 License

本项目采用 [**MIT License**](LICENSE)（Copyright © 2026 cslht11）。

即：允许任何人自由使用、复制、修改、合并、发布、分发、再许可和/或销售本软件副本；只需保留上述版权声明与许可声明。**本软件按"原样"提供，不附带任何明示或默示担保。**

> 注意：本补丁集修改的是 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 的编译产物。DSH 本身的代码与许可以官方仓库 [LICENSE](https://github.com/deepseek-ai/deepseek-harness) 为准；本许可证仅覆盖本仓库中的补丁、脚本与文档等原创内容。

---

## 📎 相关资源

- DeepSeek Harness 官方仓库：<https://github.com/deepseek-ai/deepseek-harness>
- DeepSeek Harness npm：`@deepseek-ai/dsh`
- 本仓库：<https://github.com/cslht11/dsh-custom-patches>
