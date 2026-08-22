# 贡献指南（Contributing）

感谢你愿意为 **dsh-custom-patches** 贡献！本指南告诉你可以贡献什么、怎么贡献、以及要注意的规范。

> 先读一下 [README](README.md)，了解这是个 **补丁集**（不是官方插件、不是源码 fork）。
> 你的贡献方式与普通"改源码"项目略有不同，请先理解它的形态。

---

## 你可以贡献什么

| 类型 | 内容 | 难度 |
|---|---|---|
| 🐛 报告问题 | 补丁应用失败、安装脚本报错、文档错误 | 低 |
| 💡 提建议 | 新功能想法、更好的安装/适配流程 | 低 |
| ✨ 新增补丁 | 为 DSH 加**新的**自定义功能 | 中 |
| 🔧 修复/更新补丁 | 官方升级后重新适配现有补丁 | 中 |
| 📝 改进文档 | 补全 README / ADAPTING / versions 等 | 低 |

---

## 🚦 开始之前

1. **看是否已有类似 Issue**：先在 [Issues](https://github.com/cslht11/dsh-custom-patches/issues) 搜索，避免重复。
2. **确认适用版本**：本项目只适配 `@deepseek-ai/dsh@0.1.1-rc.2`（见 [versions.md](versions.md)）。如果你想适配其他版本，是**另一类工作**（见下文「适配新版」）。

---

## 🐛 报告问题 / 💡 提建议

在 [Issues](https://github.com/cslht11/dsh-custom-patches/issues) 新建 Issue，尽量包含：

- **现象**：发生了什么，完整报错信息（`patch` 的 `Hunk #N failed` 输出尤其有用）
- **环境**：操作系统（macOS/Linux/Windows）、DSH 版本（`dsh --version`）、Node 版本
- **复现步骤**：从 `clone` 到出问题的完整命令序列
- **期望**：你希望的结果

> 若不知道是否是自己操作问题，可先附上 `bash install-dsh-custom.sh -y` 的完整输出。

---

## ✨ 新增一个功能补丁（核心贡献流程）

本项目的贡献单元是 **补丁文件**（`patches/<插件包>/<文件名>.patch`）。一个功能可能涉及多个插件文件，就提交多个补丁。

### 第 1 步：在本地 DSH 里实现功能
在你自己的 DSH 安装（`node_modules/@deepseek-ai/<包>/lib/`）里直接改编译产物代码，实现新功能。
- **务必先保留原始备份**（`.bak`）：`cp <文件> <文件>.bak`
- 遵循「补丁最小化」：只改**必要几处**，不做无关改动
- 在改动中留下**清晰的功能标记**（如 `editLastPrompt`、`recallHistory`），方便后续 grep 定位和排查

### 第 2 步：生成补丁
用 `diff -u` 对比 `.bak`（原始）与改动后文件，得到补丁：
```bash
diff -u <包>/lib/<文件>.bak <包>/lib/<文件> > <名>.patch
```

### 第 3 步：命名与放置
- 文件名用**相对插件包的路径**，如 `dsh-client-ui-conversation-lib-client.js.patch`
- 若与版本相关，加版本后缀（如 `.rc7`）
- 放到 `patches/<插件包>/` 目录下

### 第 4 步：登记到脚本
把新补丁加入 **`install-dsh-custom.sh` 和 `apply-dsh-patches.sh` 的 `FILES` 数组**，格式：
```
相对插件路径|仓库中的补丁路径|内置检测标记
```
> `install-dsh-custom.sh` 与 `apply-dsh-patches.sh` 都要登记，保持两者同步。

### 第 5 步：本地验证（必须）
在**干净环境**（或先恢复原始文件）跑一遍，确认补丁可干净应用：
```bash
# 恢复原始（模拟别人的机器）
for e in dsh-host-apiproxy/lib/index.js dsh-agent-loop/lib/index.js dsh-client-connection/lib/client.js dsh-client-runtime/lib/client.js dsh-client-ui-conversation/lib/client.js; do
  cp "$(npm root -g)/@deepseek-ai/dsh/node_modules/@deepseek-ai/$e.bak" "$(npm root -g)/@deepseek-ai/dsh/node_modules/@deepseek-ai/$e"
done

# 一键应用全部补丁
bash install-dsh-custom.sh -y
```
- 全部 `[OK] applied` 且无 `FAIL` = 通过
- 重启 `dsh web`，实测新功能确实生效
- 把「验收信号」补充到 README（参考现有功能的验收清单）

### 第 6 步：提交 & 发起合并请求
```bash
git add -A
git commit -m "feat: 添加 <功能说明>"
git push origin <你的分支名>
```
然后在 GitHub 上发起 **Pull Request** 到这个仓库的 `main` 分支，描述：
- 功能是什么、怎么用
- 涉及哪些插件文件
- 在哪个 DSH 版本上验证过
- 补丁的应用/恢复方式

---

## 🔧 适配官方新版（维护者/贡献者）

官方升级后补丁可能失效。完整流程见 **[ADAPTING.md](ADAPTING.md)**，要点：
1. 装好新版官方包
2. 用 `bash install-dsh-custom.sh -y` 一键检测——**新脚本会自动跳过官方已内置的功能**；也可手动 `grep` 功能标记确认（见 [versions.md](versions.md)）
3. 对失效补丁，用 `diff` 重新生成（通常是少数几行上下文变了）
4. 更新脚本 `FILES` 数组与 [versions.md](versions.md)（追加新版本一行）
5. 本地验证后再提交

> 官方升级会覆盖 node_modules 里的安装，**每次官方升级都需要重新应用本补丁集**——这是补丁方案的天性，不是 bug。

---

## 📝 改进文档

欢迎改进 README / ADAPTING / versions / 本文件。注意：
- 术语一致性：**主入口脚本一律写 `install-dsh-custom.sh`**（`apply-dsh-patches.sh` 是备选，如需提及请注明）
- 命令与示例要**可在全新 clone 后直接执行**（优先 HTTPS 克隆，路径用 `npm root -g` 动态取）
- 语言：README/CONTRIBUTING 面向使用者的部分可用中文；代码注释保持英文，便于 AI/机器人解析

---

## ✅ 代码与文档规范（小结）

- **补丁最小化**：每次只改必要几处，避免无关改动
- **标记清晰**：每个功能留可 grep 的功能标记
- **脚本同步**：`install-dsh-custom.sh` 与 `apply-dsh-patches.sh` 的 `FILES` 保持一致
- **可验证**：任何改动都要有"如何验证成功/失败"的明确步骤
- **版本记录**：涉及版本适配时，更新 `versions.md`

---

## 🤝 行为守则（简单版）

- 友好、具体、对事不对人
- 报告问题时给出完整信息（环境 + 报错 + 复现步骤）
- 欢迎分歧，但请提供依据

---

## 📎 参考

- 项目说明见 [README.md](README.md)
- 版本适配见 [ADAPTING.md](ADAPTING.md)
- 版本追踪见 [versions.md](versions.md)
- 仓库主页：<https://github.com/cslht11/dsh-custom-patches>
