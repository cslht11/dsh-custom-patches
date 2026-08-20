# 事故复盘：rc.8 补丁适配中的 3 个 Bug（2026-08-19）

## 现象

执行 `dsh web` 后浏览器报错：
```
Failed to load plugins
failed to import loader entry abcbd115 (@deepseek-ai/dsh-client-ui-conversation):
client-modules: bundle /plugins/@deepseek-ai/dsh-client-ui-conversation/client.js?rev=640a5a669b2b
loaded without registering "@deepseek-ai/dsh-client-ui-conversation" via __ModuleLoader__.load
```

根因是补丁文件有语法错误 → JS 解析崩溃 → 插件从未注册。

---

## Bug 1：`.join("` 内出现真实换行

### 问题
补丁中的 JS 代码：
```javascript
// 本应是：
setEditText(data.content.filter((block) => block.type === "text").map((block) => block.text).join("\n"));

// 实际变成了：
setEditText(data.content.filter((block) => block.type === "text").map((block) => block.text).join("
"));
```

`\n` 应该是转义字符（反斜杠 + n），但变成了真实换行 → JS 字符串语法错误。

### 根因
Python 脚本通过 **未加引号的 heredoc** 执行：
```bash
python3 << PYEOF   # ← 错误！未加引号
edit_state = '''...join("\\n"));'''
PYEOF
```

未加引号时，bash 预处理 `\\n` → `\n`（反斜杠 + n），Python 再把 `\n` 解释为真实换行字节。

### 修复
```bash
python3 << 'PYEOF'   # ← 正确！加引号防止 bash 处理
edit_state = '''...join("\\n"));'''
PYEOF
```

### 教训
- 任何含 `\n`、`\t`、`\\` 等转义序列的字符串，**必须用 `<< 'EOF'`（单引号定界符）**，禁止用 `<< EOF`
- 生成补丁后先用 `node --check <目标文件>` 验证语法
- 审查补丁文件中的字符串字面量是否完整

---

## Bug 2：Hunk 行数计数不匹配

### 问题
补丁第 128 行的 hunk 头：
```
@@ -5283,8 +5357,98 @@
```
声明新增 98 行，实际只有 97 行，差额 1。

### 根因
修复 Bug 1 时手动编辑了补丁文件（把两行合并为一行），但未同步更新 hunk 头的行数计数。

### 修复
```python
# 校验脚本自动发现并修正
s = s.replace("@@ -5283,8 +5357,98 @@", "@@ -5283,8 +5357,97 @@")
```

### 教训
- **永远不要手动编辑补丁文件的行内容**而不更新 hunk 头
- 修改补丁后必须用行数校验脚本验证所有 hunk 的 `old_n` 和 `new_n`
- 推荐工作流：改源码 → 重新 `diff -u` 生成新补丁，而非编辑旧补丁

---

## Bug 3：补丁头部路径缺少 `@deepseek-ai/` 前缀

### 问题
rc.7 补丁头部：
```
--- @deepseek-ai/dsh-client-ui-conversation/lib/client.js.bak
+++ @deepseek-ai/dsh-client-ui-conversation/lib/client.js
```

rc.8 补丁头部（错误）：
```
--- lib/client.js.bak
+++ lib/client.js
```

### 根因
生成补丁时，`cd` 进入了插件包目录，`diff -u lib/client.js.bak lib/client.js` 的路径是相对于当前目录的，缺少了 `@deepseek-ai/dsh-client-ui-conversation/` 前缀。

### 修复
```python
s = s.replace("--- lib/client.js.bak\t", "--- @deepseek-ai/dsh-client-ui-conversation/lib/client.js.bak\t")
s = s.replace("+++ lib/client.js\t", "+++ @deepseek-ai/dsh-client-ui-conversation/lib/client.js\t")
```

### 教训
- `diff -u` 生成补丁时，**始终从插件包目录的父级或更上级运行**，使头部路径包含完整的包名
- 或者生成后统一替换头部路径
- 补丁头部路径格式应与 `install-dsh-custom.sh` 中 `FILES` 数组的 `rel` 字段一致

---

## 预防措施清单

### 补丁生成后必须验证

```bash
# 1. JS 语法检查（捕获 Bug 1）
node --check <打补丁后的文件>

# 2. hunk 行数校验（捕获 Bug 2）
python3 -c "
import re
lines = open('补丁文件.patch').read().split('\n')
for i, l in enumerate(lines):
    if l.startswith('@@ '):
        m = re.match(r'@@ -(\d+),?(\d*) \+(\d+),?(\d*) @@', l)
        old_n, new_n = int(m.group(2) or 1), int(m.group(4) or 1)
        # 数上下文中的 +/- 行
        # 若 old_n 或 new_n 与计数不符 → 报错
"

# 3. 补丁头部路径检查（捕获 Bug 3）
head -2 补丁文件.patch | grep -q '@deepseek-ai' || echo '警告：头部缺少 @deepseek-ai/ 前缀'

# 4. 在干净官方文件上 dry-run（确保补丁可应用）
patch --dry-run -N -p1 <干净官方文件> < 补丁文件.patch
```

### 脚本工作流规范

1. **修改源码 → 重新 `diff -u` 生成补丁**，不要手动编辑旧补丁
2. 生成补丁时**从正确的父目录运行 `diff`**
3. 涉及字符串转义的代码，**用 `<< 'EOF'` 而非 `<< EOF`**
4. 补丁生成后**依次执行上述 4 项验证**，全部通过再提交
5. 提交前在**干净环境完整跑一遍 `install-dsh-custom.sh -y`**

---

## 相关文件

- 修复提交：`62028ce`（`fix: 修复 rc8 ui-conversation 补丁三处问题`）
- 补丁文件：`patches/client-ui-conversation/dsh-client-ui-conversation-lib-client.js.rc8.patch`
- 安装脚本：`install-dsh-custom.sh`（负责补丁应用）