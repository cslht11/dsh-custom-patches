# SSH 远程工作区插件（独立仓库）

DSH 的 SSH 远程工作区能力已迁移到**独立仓库**：

## 🔗 [cslht11/dsh-ssh-remote](https://github.com/cslht11/dsh-ssh-remote)

**功能**：多机 SSH 远程工作区插件（多池并行）——同时连接多台服务器，Agent 直接查看/编辑/执行远程文件。

- **上游项目**：[flymysql/dsh-remote](https://github.com/flymysql/dsh-remote)（MIT，v0.5.10）→ 本插件 fork 改造为 0.6.0
- **适配版本**：`@deepseek-ai/dsh@0.1.0-rc.8`（按 rc.8 用户 preset 挂载）
- **安装**：`git clone https://github.com/cslht11/dsh-ssh-remote.git` → 按该仓库 README 安装

## 为什么独立成仓库

| 仓库 | 职责 |
|---|---|
| **dsh-custom-patches**（本仓库） | DSH 官方版本的**补丁集**（输入历史 + 编辑重发），随官方版本更新适配 |
| **dsh-ssh-remote**（独立） | 完整的 SSH 远程工作区**插件**（SSH 连接池 + SFTP + 远程工具），独立版本管理与维护 |

SSH 插件体量较大（含 ssh2 依赖、连接池、前后端），且后续维护节奏独立于官方版本适配，故单独立项。