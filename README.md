# DSH 自定义增强补丁（Custom Enhancements for DeepSeek Harness）

为 [DeepSeek Harness (DSH)](https://github.com/deepseek-ai/deepseek-harness) Web GUI 添加两个官方暂未提供的实用功能：
**① 输入框 ↑/↓ 键发送历史** 与 **② 编辑最后一条消息并重新生成（Codex 风格）**。

- 适配版本：**`@deepseek-ai/dsh@0.1.1-rc.2`**
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
| **macOS** | ✅ 原生支持 | 自带的 `bash`/`patch` 即可（`pgrep` 也已内置） |
| **Linux** | ✅ 原生支持 | 自带 `patch`；部分精简发行版需 `sudo apt install patch` |
| **Windows** | ✅ 装完 Git for Windows 即可 | **Git for Windows 已自带** `bash`、`diff`、`patch` 与 `git`，无需再装。唯一用到的 `pgrep` 只在「重启」那一条命令里出现，Windows 用 `taskkill` 替代即可（见下） |

**统一前置条件**（任意平台）：
- 已安装 **Node.js**（含 `npm`）
- 已用 npm **全局安装 `@deepseek-ai/dsh`**（当前最新适配 `0.1.1-rc.2`；**老版本 rc.7 / rc.8 用户无需升级**，安装脚本带版本号参数即可，见「老版本 DSH 用户」）；或用源码构建（见「源码构建（monorepo）用户」）

> **不装命令行工具也能用**：最省事的办法是把这个仓库链接（`https://github.com/cslht11/dsh-custom-patches`）发给你的 AI 助手，让它按本文档的「快速开始」在你的机器上完成安装与配置——它会自行处理 Windows 的 `taskkill` 等差异。

---

## 🚀 快速开始（各平台通用）

一共四步，**推荐用 HTTPS 克隆**（无需配置 SSH key）。把这整段丢给 AI 也能照着完成：

```bash
# 1) 安装匹配版本的 DSH（已装且版本正确可跳过）
npm install -g @deepseek-ai/dsh@0.1.1-rc.2
dsh --version          # 应输出 0.1.1-rc.2

# 2) 克隆本仓库（HTTPS，对所有人可用）
git clone https://github.com/cslht11/dsh-custom-patches.git
cd dsh-custom-patches

# 3) 一键安装（-y 跳过交互确认；脚本会自动定位 DSH、校验版本、检测官方是否已内置、备份并应用）
bash install-dsh-custom.sh -y

# 4) 重启 DSH（macOS / Linux）
kill $(pgrep -f 'dsh web') 2>/dev/null && sleep 1; dsh web
```

> **Windows 重启**：把上一步换成 `taskkill //F //IM node.exe`（或结束对应 node 进程）后重新 `dsh web` 即可；`pgrep` 只在重启这里用到。
> **源码构建（monorepo）用户**：把第 3 步换成 `DSH_SOURCE=/path/to/deepseek-harness bash install-dsh-custom.sh -y`，只需重建/重启你的开发服务（详见「源码构建（monorepo）用户」一节）。

然后**硬刷新**浏览器页面（`Cmd+Shift+R` / `Ctrl+Shift+R`）：
- 输入框按 **↑** 即可翻历史
- 最后一条用户消息 **hover（鼠标悬停）** 出现 **✏️ 编辑** 按钮

> 也可以把本仓库链接 `https://github.com/cslht11/dsh-custom-patches` 直接发给你的 AI 助手，
> 让它按本文档的「快速开始」步骤在你的机器上完成配置；文档中的命令均可直接执行。

---

## 🧩 老版本 DSH 用户（0.1.0-rc.7 / 0.1.0-rc.8）

**还没升级官方、仍用老版本 DSH？不需要升级**，直接给安装脚本加上你的版本号即可。仓库同时保留了 rc.7 / rc.8 / 0.1.1-rc.2 三个版本的适配（版本追踪见 [versions.md](versions.md)）：

| 你的 DSH 版本 | 一键安装命令 |
|---|---|
| **0.1.1-rc.2**（最新） | `bash install-dsh-custom.sh -y`（默认） |
| **0.1.0-rc.8** | `bash install-dsh-custom.sh -y 0.1.0-rc.8` |
| **0.1.0-rc.7** | `bash install-dsh-custom.sh -y 0.1.0-rc.7` |
| 0.1.0-rc.6 及更早 | ❌ 无独立补丁文件（仓库自 rc.7 起发布），建议升级官方后使用 |

基础脚本同样支持：`bash apply-dsh-patches.sh 0.1.0-rc.8`。

> **为什么能跨版本？** 官方主要在 `dsh-client-ui-conversation` 包里调整界面布局，所以只需按版本切换这一个补丁（`.rc7` / `.rc8` / `.rc2` 三份文件都保留在 `patches/` 下）；其余 4 个补丁（host-apiproxy / agent-loop / client-runtime / client-connection）在 rc.7 → rc.8 → rc.2 各版本间**内容不变，直接通用**。
>
> **不想记版本？** 直接跑 `bash install-dsh-custom.sh -y`，若本机版本与默认适配版本不符，脚本会明确报错并提示你用哪个参数重试——不会误打补丁。

---

## 🛠 分步说明（想了解细节再看）

### 第 1 步：确认 DSH 版本
```bash
npm install -g @deepseek-ai/dsh@0.1.1-rc.2   # 装到匹配版本
dsh --version                                 # 确认是 0.1.1-rc.2
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
3. **校验版本**（默认期望 `0.1.1-rc.2`；老版本用户加版本号即可，如 `bash install-dsh-custom.sh -y 0.1.0-rc.8`；不匹配会拒绝并提示正确用法）
4. **检测官方是否已内置功能**——若目标文件已含功能标记（例如官方新版把这些功能收编了），自动跳过对应补丁
5. 对需要应用的补丁**逐一备份（生成 `.bak`）并应用**
6. 汇总报告 + 提示重启

> 备选：`bash apply-dsh-patches.sh`（功能相同，但没有版本诊断与内置检测；两者等效地应用同一套补丁，任选其一即可）。老版本用户同样加版本号：`bash apply-dsh-patches.sh 0.1.0-rc.8`。

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

## 🧩 源码构建（monorepo）用户

如果你不是用 `npm install -g` 装 DSH，而是**从源码克隆下来**（比如官方 [deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) 的 pnpm monorepo，自己 `pnpm` + `tsdown` 构建、直接 serve 各包产物），同样可以打这套补丁——**补丁内容完全通用**，只是目标文件位置不同，脚本已支持这种布局。

### 第一步：确认两件事
- 你有 DSH 的**源码仓库根目录**（就是一个含 `packages/` 和 `pnpm-workspace.yaml` 的目录），例如 `/path/to/deepseek-harness`
- 各插件包**已构建**（生成了 `lib/` 产物；未构建时只有 `src/`，没有可打补丁的文件）

### 第二步：设置 `DSH_SOURCE` 并运行一键脚本
```bash
export DSH_SOURCE=/path/to/deepseek-harness          # 指向源码仓库根
bash install-dsh-custom.sh -y
```
脚本检测到 `DSH_SOURCE` 后会自动切换到源码布局：
- 在 `<DSH_SOURCE>/packages/**/lib/` 下定位目标文件、备份、应用
- **跳过 npm 版本校验**（源码没有 `0.1.1-rc.2` 这种版本号），但请确认你的源码 checkout 对应 rc.2 时代的代码
- 应用完成后，**重建/重启你的 DSH 开发服务**（和你平时重启方式一致），再硬刷新页面

### 源码布局下的目标文件（对应关系）
| npm 包名 | 源码中的包目录 | 补丁目标文件（构建后） |
|---|---|---|
| `@deepseek-ai/dsh-host-apiproxy` | `packages/host/apiproxy` | `lib/index.js` |
| `@deepseek-ai/dsh-agent-loop` | `packages/core/agent-loop` | `lib/index.js` |
| `@deepseek-ai/dsh-client-connection` | `packages/client/connection` | `lib/client.js` |
| `@deepseek-ai/dsh-client-runtime` | `packages/client/runtime` | `lib/client.js` |
| `@deepseek-ai/dsh-client-ui-conversation` | `packages/client/ui-conversation` | `lib/client.js` |

> 也就是说：一片补丁中写的 `dsh-xxx/lib/file.js`，在源码布局下就是 `<DSH_SOURCE>/packages/<对应目录>/lib/file.js`——内容一致，只是根不同。这也是为什么源码用户能直接趟通同一套补丁。

### 如何恢复（源码布局）
```bash
for e in \
  host/apiproxy/lib/index.js \
  core/agent-loop/lib/index.js \
  client/connection/lib/client.js \
  client/runtime/lib/client.js \
  client/ui-conversation/lib/client.js; do
  cp "$DSH_SOURCE/packages/$e.bak" "$DSH_SOURCE/packages/$e"
done
```

> 想了解源码布局的更多细节，或如何为一处失效补丁重新适配，见 [ADAPTING.md](ADAPTING.md)。

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
# 1) 检测官方是否有新版（自动对比本地/最新/适配版本；也可指定版本：bash check-update.sh 0.1.0-rc.8）
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
├── install-dsh-custom.sh   # 【推荐】一键安装（诊断版本 + 检测官方是否内置 + 备份 + 应用；支持老版本参数）
├── apply-dsh-patches.sh    # 基础安装脚本（自动定位、校验版本、备份、应用；支持老版本参数）
├── check-update.sh         # 检测官方是否有新版本，评估是否需要重新适配（可指定版本）
├── versions.md             # 版本追踪表（官方版本 × 补丁适用性 × 官方是否内置功能）
├── ADAPTING.md             # 适配官方新版的操作手册（面向维护者）
├── CONTRIBUTING.md         # 贡献指南（怎么报问题、加功能、适配、改进文档）
├── POSTMORTEM.md           # 事故复盘与补丁生成规范（避免重复踩坑）
├── docs/
│   └── SSH-REMOTE.md       # SSH 远程工作区插件 → 指向独立仓库 cslht11/dsh-ssh-remote
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

**想直接动手贡献？** 完整的流程、规范与验证要求见 **[CONTRIBUTING.md](CONTRIBUTING.md)**（报问题 / 新增补丁 / 适配新版 / 改进文档）。

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
