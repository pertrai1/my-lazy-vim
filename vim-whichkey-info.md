# Neovim / which-key Reference

Quick reference for finding LSP usages and using which-key discovery in my LazyVim setup (`~/.config/nvim`).

## Finding symbol usages ("N usages" inline text)

- The **"3 usages"** style inline text comes from `Wansmer/symbol-usage.nvim` (display-only virtual text, no keymaps).
- To actually **jump to the usages**, put the cursor on the symbol and press `gr` (References). LazyVim opens them in the picker.

### Core LSP navigation keymaps (buffer-local, set on `LspAttach`)

| Keys | Action |
|------|--------|
| `gr` | References (the usages) |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gI` | Go to implementation |
| `gy` | Go to type definition |
| `K`  | Hover docs |
| `gK` | Signature help |
| `<leader>ca` | Code action |
| `<leader>cr` | Rename symbol (renames all usages) |

> These only appear once an LSP is attached to the buffer. Confirm with `:LspInfo`.

## which-key discovery — no leader key required

which-key (v3) auto-hooks many prefixes, not just `<leader>`. Press the prefix and **pause** to see the menu:

| Prefix | Shows |
|--------|-------|
| `g` | Goto / LSP maps (`gr`, `gd`, `gI`, `gy`, ...) |
| `z` | Folds & spelling (`zR`/`zM` open/close all, `z=` spelling) |
| `]` / `[` | Next/prev navigation (`]d`/`[d` diagnostics, `]e`/`[e` errors, `]h`/`[h` git hunks) |
| `"` | Register list before pasting |
| `<C-w>` | Window management |
| `s` | Flash/leap jump (setup dependent) |

### My custom which-key helpers (`~/.config/nvim/lua/plugins/which-key.lua`)

| Keys | Action |
|------|--------|
| `<leader>hb` | Buffer-local keymaps (best for LSP `g*` maps in the current file) |
| `<leader>hk` | All global keymaps |
| `<leader>hK` | `:WhichKey` full browser |

> `<leader>hb` only lists the LSP `g*` maps when the cursor is in a file with an active LSP (buffer-local, set after LspAttach).

## Tip: popup speed

If the which-key popup feels slow, it's the `timeoutlen` (default 1000ms). Lower it in `lua/config/options.lua`:

```lua
vim.o.timeoutlen = 400
```
