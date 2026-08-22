# DSH Custom Enhancements
> 📖 [中文版](README.zh.md)


Adds two practical features to the [DeepSeek Harness (DSH)](https://github.com/deepseek-ai/deepseek-harness) Web GUI that are not yet provided officially:
**① Composer ↑/↓ key send history** and **② Edit last message and regenerate (Codex-style)**.

- Target version: **`@deepseek-ai/dsh@0.1.1-rc.2`**
- License: **MIT** (see [LICENSE](LICENSE))
- Maintainer: cslht11 (<heitieya@163.com>)

> **What this is / isn't**: This is a set of **compiled-artifact patches**, not an official plugin, not a source fork.
> It uses `diff`/`patch` to directly modify DSH's installed npm package files (compiled JS in `node_modules`),
> adding two features that DSH doesn't have yet. **Any npm reinstall / DSH upgrade will overwrite these patches — re-apply after each upgrade.**

---

## ✨ Features

### 1. Composer Arrow-Up/Down History (terminal-like)
- Press **↑** in the composer to recall the last sent message; keep pressing ↑ to go further back; **↓** to go forward
- History position auto-resets when editing input text
- Compatible with Chinese IME (no accidental trigger during pinyin composition), multi-line text (trigger only at first/last line), and consecutive duplicate dedup

### 2. Edit Last Message and Regenerate (Codex-style)
- Hover over the **last user message** to see an **✏️ Edit** button
- Click to turn the message into an editable text box (pre-filled with original text)
- After editing, click **"Save & regenerate"**: the new text replaces the original, **discards all AI replies / tool calls after it**, and AI regenerates from the new content
- Earlier messages are preserved as read-only; editing is blocked while AI is working (conflict prevention)
- Click **Cancel** to restore original

**How it works**: Editing uses DSH session layer's **surface replace** (append-only log + shadow replacement) — history is preserved, but the model and UI only see the replaced sequence.

---

## ⚠️ Platform & Prerequisites

The install script is written in **bash** and depends on **Unix command-line tools**:

| Platform | Supported | Notes |
|---|---|---|
| **macOS** | ✅ Native | Built-in `bash`/`patch` (`pgrep` also built-in) |
| **Linux** | ✅ Native | `patch` built-in; some minimal distros need `sudo apt install patch` |
| **Windows** | ✅ After Git for Windows | **Git for Windows includes** `bash`, `diff`, `patch`, and `git`. The only `pgrep` usage is in the restart command; Windows uses `taskkill` instead (see below) |

**Universal prerequisites** (any platform):
- **Node.js** (with `npm`) installed
- **`@deepseek-ai/dsh`** installed globally via npm (currently targeting `0.1.1-rc.2`; **users on older rc.7 / rc.8 do NOT need to upgrade** — pass your version to the install script, see "Older DSH Versions" below); or built from source (see "Source Build (monorepo) Users" below)

> **No CLI tools needed**: The easiest path is to send this repo link (`https://github.com/cslht11/dsh-custom-patches`) to your AI assistant and let it follow the "Quick Start" section to install and configure on your machine — it will handle Windows `taskkill` differences automatically.

---

## 🚀 Quick Start (all platforms)

Four steps total, **HTTPS clone recommended** (no SSH key needed). You can paste this whole block to an AI assistant:

```bash
# 1) Install matching DSH version (skip if already installed and correct version)
npm install -g @deepseek-ai/dsh@0.1.1-rc.2
dsh --version          # should output 0.1.1-rc.2

# 2) Clone this repo (HTTPS, works for everyone)
git clone https://github.com/cslht11/dsh-custom-patches.git
cd dsh-custom-patches

# 3) One-click install (-y skips interactive confirm; script auto-locates DSH, validates version, detects built-ins, backs up, and applies)
bash install-dsh-custom.sh -y

# 4) Restart DSH (macOS / Linux)
kill $(pgrep -f 'dsh web') 2>/dev/null && sleep 1; dsh web
```

> **Windows restart**: replace step 4 with `taskkill //F //IM node.exe` (or kill the node process) then `dsh web`. `pgrep` is only used in the restart command.
> **Source build (monorepo) users**: replace step 3 with `DSH_SOURCE=/path/to/deepseek-harness bash install-dsh-custom.sh -y`, then rebuild/restart your dev server (see "Source Build (monorepo) Users" below).

Then **hard-refresh** the browser page (`Cmd+Shift+R` / `Ctrl+Shift+R`):
- Press **↑** in the composer to recall history
- Hover over the **last user message** to see the **✏️ Edit** button

> You can also send this repo link `https://github.com/cslht11/dsh-custom-patches` directly to your AI assistant and let it follow the "Quick Start" steps to configure on your machine; all commands in this document are directly executable.

---

## 🧩 Older DSH Versions (0.1.0-rc.7 / 0.1.0-rc.8)

**Still on an older DSH version? No upgrade needed** — just pass your version to the install script. The repo keeps patches for rc.7 / rc.8 / 0.1.1-rc.2 (version tracking in [versions.md](versions.md)):

| Your DSH Version | One-click Command |
|---|---|
| **0.1.1-rc.2** (latest) | `bash install-dsh-custom.sh -y` (default) |
| **0.1.0-rc.8** | `bash install-dsh-custom.sh -y 0.1.0-rc.8` |
| **0.1.0-rc.7** | `bash install-dsh-custom.sh -y 0.1.0-rc.7` |
| 0.1.0-rc.6 and earlier | ❌ No standalone patches (repo started publishing at rc.7); please upgrade DSH first |

The base script also supports: `bash apply-dsh-patches.sh 0.1.0-rc.8`.

> **Why cross-version works**: Official changes mainly touch `dsh-client-ui-conversation` layout, so only that one patch needs version switching (`.rc7` / `.rc8` / `.rc2` files are all kept under `patches/`); the other 4 patches (host-apiproxy / agent-loop / client-runtime / client-connection) are **identical across rc.7 → rc.8 → rc.2** and apply universally.
>
> **Don't want to remember versions?** Just run `bash install-dsh-custom.sh -y`; if your local version doesn't match the default target, the script will explicitly error and tell you which parameter to retry with — it won't mis-patch.

---

## 🛠 Step-by-Step Details

### Step 1: Confirm DSH Version
```bash
npm install -g @deepseek-ai/dsh@0.1.1-rc.2   # install matching version
dsh --version                                 # confirm it's 0.1.1-rc.2
```

### Step 2: Clone the Repo
HTTPS (recommended, works everywhere):
```bash
git clone https://github.com/cslht11/dsh-custom-patches.git
cd dsh-custom-patches
```
SSH (optional, requires GitHub SSH key configured):
```bash
git clone git@github.com:cslht11/dsh-custom-patches.git
cd dsh-custom-patches
```

### Step 3: Run the Install Script
Recommended: the **one-click script** with version diagnosis and built-in detection:
```bash
bash install-dsh-custom.sh -y
```
The script will automatically:
1. Locate DSH install dir (probes both system-level and user-level global paths)
2. Read local version and query npm for latest, giving a version diagnosis
3. **Validate version** (default expects `0.1.1-rc.2`; older version users add version arg, e.g. `bash install-dsh-custom.sh -y 0.1.0-rc.8`; mismatch aborts with correct usage hint)
4. **Detect if official already has the feature** — if the target file already contains feature markers (e.g. official bundled them), automatically skip that patch
5. For patches that need applying: **backup each file (`.bak`) and apply**
6. Summary report + restart hint

> Alternative: `bash apply-dsh-patches.sh` (same functionality, but no version diagnosis or built-in detection; both apply the same patch set). Older version users also add version arg: `bash apply-dsh-patches.sh 0.1.0-rc.8`.

### Step 4: Restart DSH
```bash
kill $(pgrep -f 'dsh web') 2>/dev/null; sleep 1; dsh web
```

### Step 5: Verify (confirm installation success)
After refreshing the page, check these **observable signals** — all met means success:
- [x] Pressing **↑** in the composer recalls the previous message
- [x] Hovering over the **last user message** shows the **✏️ Edit** button
- [x] Clicking edit → changing content → "Save & regenerate" replaces and regenerates

> Self-diagnosis via script: run `bash install-dsh-custom.sh -y` again; if it outputs *"All features already present (built-in or applied). Nothing to do."* then all features are in place.

---

## 🧩 Source Build (monorepo) Users

If you don't use `npm install -g` for DSH but instead **cloned the source** (e.g. official [deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) pnpm monorepo, built with `pnpm` + `tsdown`, and serve packages directly), you can still apply these patches — **patches are fully portable**, only target file paths differ, and the script supports this layout.

### Step 1: Confirm Two Things
- You have the **DSH source repo root** (a directory containing `packages/` and `pnpm-workspace.yaml`), e.g. `/path/to/deepseek-harness`
- Each plugin package has been **built** (produced `lib/` artifacts; if only `src/` exists, there's nothing to patch)

### Step 2: Set `DSH_SOURCE` and Run the One-click Script
```bash
export DSH_SOURCE=/path/to/deepseek-harness          # point to source repo root
bash install-dsh-custom.sh -y
```
When the script detects `DSH_SOURCE`, it automatically switches to source layout:
- Locates target files under `<DSH_SOURCE>/packages/**/lib/`, backs up, and applies
- **Skips npm version validation** (source doesn't have `0.1.1-rc.2` version strings), but please ensure your source checkout matches rc.2-era code
- After applying, **rebuild/restart your DSH dev server** (same as your usual restart flow), then hard-refresh the browser

### Source Layout Target File Mapping
| npm Package | Source Package Dir | Patch Target File (built) |
|---|---|---|
| `@deepseek-ai/dsh-host-apiproxy` | `packages/host/apiproxy` | `lib/index.js` |
| `@deepseek-ai/dsh-agent-loop` | `packages/core/agent-loop` | `lib/index.js` |
| `@deepseek-ai/dsh-client-connection` | `packages/client/connection` | `lib/client.js` |
| `@deepseek-ai/dsh-client-runtime` | `packages/client/runtime` | `lib/client.js` |
| `@deepseek-ai/dsh-client-ui-conversation` | `packages/client/ui-conversation` | `lib/client.js` |

> In other words: a patch path like `dsh-xxx/lib/file.js` maps to `<DSH_SOURCE>/packages/<corresponding-dir>/lib/file.js` in source layout — same content, different root. That's why source-build users can use the exact same patch set.

### How to Restore (source layout)
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

> For more source-layout details or how to re-adapt a broken patch, see [ADAPTING.md](ADAPTING.md).

---

## ↩️ How to Restore Original (uninstall patches)

The install script backs up each modified file as `.bak`. To restore, copy those backups back (path is dynamically obtained via `npm root -g`, works with any global install layout):

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

## 🔄 Keeping Up with Official Updates

Official upgrades overwrite these patches (because they modify `node_modules` compiled artifacts). Recommended workflow:

```bash
# 1) Check for new official version (auto-compares local/latest/targeted; can specify version: bash check-update.sh 0.1.0-rc.8)
bash check-update.sh

# 2) Upgrade official
npm install -g @deepseek-ai/dsh@<new-version>

# 3) Re-apply (includes built-in detection; succeeds directly if official didn't change much)
bash install-dsh-custom.sh -y
```

- **Did official already bundle our features?** The one-click script auto-detects and skips built-in patches; you can also manually confirm using the grep method in [`versions.md`](versions.md).
- **Patches broke?** Follow [`ADAPTING.md`](ADAPTING.md) to re-adapt and append a new version row in `versions.md`.

> ⚠️ If `patch` errors after upgrade, the new version changed the relevant code — re-adapt per `ADAPTING.md`.

---

## 📦 Project Structure

```
dsh-custom-patches/
├── README.md               # This file (English)
├── README.zh.md            # 中文版
├── install-dsh-custom.sh   # 【Recommended】One-click install (version diagnosis + built-in detection + backup + apply; supports older version args)
├── apply-dsh-patches.sh    # Basic install script (auto-locate, validate version, backup, apply; supports older version args)
├── check-update.sh         # Check if official has a new version, assess re-adaptation need (can specify version)
├── versions.md             # Version tracking table (official version × patch compatibility × official built-in status)
├── ADAPTING.md             # Operation manual for adapting to new official versions (for maintainers)
├── CONTRIBUTING.md         # Contribution guide (issues, features, adaptations, docs)
├── POSTMORTEM.md           # Postmortem and patch generation standards (avoid repeat mistakes)
├── docs/
│   └── SSH-REMOTE.md       # SSH remote workspace plugin → points to separate repo cslht11/dsh-ssh-remote
├── LICENSE                 # MIT License
└── patches/                # Patch files (organized by plugin package)
    ├── host-apiproxy/            → Adds session.editLastPrompt endpoint
    ├── agent-loop/               → turn() skips duplicate messages with same id
    ├── client-connection/        → Client RPC surface + schema mirror
    ├── client-runtime/           → editLastPrompt + folder-aware replace shadow
    └── client-ui-conversation/   → Input history + edit button UI
```

> These 5 patches correspond to 5 npm plugin packages: `dsh-host-apiproxy` · `dsh-agent-loop` · `dsh-client-connection` · `dsh-client-runtime` · `dsh-client-ui-conversation`

---

## 🤔 Can I Modify This? How to Contribute / Contact

**Yes, contributions welcome.** This project is **MIT** licensed — free to use, modify, and redistribute.

Understand its shape first, then decide how to "modify":

- **Want to use these features directly**: clone → `bash install-dsh-custom.sh -y` (see "Quick Start").
- **Want to add your own features**: This repo is a **patch set**. To extend it, modify the compiled JS files in your local DSH's `node_modules/@deepseek-ai/<package>/lib/`, then generate a patch with `diff` and add it to `patches/` in this repo. Full workflow in [**How Maintainers Add Features**](#-how-maintainers-add-features) below.
- **Want to modify DSH itself at source level**: That's a separate path — fork [deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) and modify directly. Note that official [CONTRIBUTING.md](https://github.com/deepseek-ai/deepseek-harness/blob/master/CONTRIBUTING.md) **does not accept external PRs** at this time, so these two features are only available via this patch approach for now.

**Questions, feedback, issues**: open an **Issue** in this repo (enabled), or email <heitieya@163.com>.

**Want to contribute directly?** Full process, standards, and verification requirements in **[CONTRIBUTING.md](CONTRIBUTING.md)** (issues / new patches / new version adaptations / docs).

---

## 🛠 How Maintainers Add Features

> For: repo maintainers (or anyone contributing a new patch).

1. Directly modify compiled JS files in your local DSH's `node_modules/@deepseek-ai/<package>/lib/` (keep `*.bak` originals).
2. Generate a patch file with `diff`:
   ```bash
   diff -u <package>/lib/<file>.bak <package>/lib/<file> > <name>.patch
   ```
3. Name patches with paths relative to the plugin package, e.g. `dsh-client-ui-conversation-lib-client.js.patch` (add version suffix for version-specific patches, e.g. `.rc7`).
4. Update the mapping array in `install-dsh-custom.sh` and `apply-dsh-patches.sh` (`FILES`), adding the new patch.
5. Commit and push:
   ```bash
   git add -A
   git commit -m "feat: add <feature description>"
   git push origin main
   ```

> Commit identity is fixed as `cslht11 <heitieya@163.com>`; push goes through gh active account cslht11.

---

## 📄 License

This project uses [**MIT License**](LICENSE) (Copyright © 2026 cslht11).

You are free to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of this software, provided you retain the above copyright notice and permission notice. **The software is provided "as is", without warranty of any kind.**

> Note: This patch set modifies compiled artifacts of [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness). DSH's own code and license are governed by the official repo [LICENSE](https://github.com/deepseek-ai/deepseek-harness); this license only covers patches, scripts, and documentation in this repo.

---

## 📎 Related Resources

- DeepSeek Harness official repo: <https://github.com/deepseek-ai/deepseek-harness>
- DeepSeek Harness npm: `@deepseek-ai/dsh`
- This repo: <https://github.com/cslht11/dsh-custom-patches>
