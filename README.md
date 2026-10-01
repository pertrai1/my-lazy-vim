# Neovim development environment

A personal [LazyVim](https://www.lazyvim.org/) configuration for TypeScript,
Angular, Python, Git, debugging, tests, REPL-driven development, and local AI
completion. Tokyo Night is the active colorscheme.

The leader key is `Space`. Press `Space` and wait for WhichKey whenever you
forget a shortcut.

## Highlights

- Language support for TypeScript, JavaScript, Angular, Python, JSON, Lua, and
  Git configuration files.
- LSP navigation, inlay hints, source actions, ESLint fixes, Prettier, and
  inline diagnostics.
- Neotest integration for Vitest, Jest, and pytest, including DAP debugging.
- Project-aware Overseer validation pipelines for OpenSpec, lint, typecheck,
  tests, and agent verification tasks when a repository exposes them.
- JavaScript/TypeScript and Python REPLs, plus operator-based code execution.
- OpenCode for repository-aware AI agent workflows.
- Private local inline completion through Minuet, llama.cpp, and Qwen Coder.
- Snacks pickers and terminals, Yazi, Diffview, Harpoon file marks, Overseer
  tasks, enhanced quickfix, folding, refactoring, snippets, and structural
  editing.
- Code quality tooling: SonarQube Connected Mode with per-repository
  credentials, line coverage in the gutter, and copy/paste detection.
- Split navigation that also works across tmux panes.

## Requirements

Required:

- Neovim 0.11 or newer; this configuration is tested with Neovim 0.12.
- Git.
- A C compiler and standard build tools.
- [ripgrep](https://github.com/BurntSushi/ripgrep) and
  [fd](https://github.com/sharkdp/fd) for fast searching.
- Node.js for TypeScript tooling and JavaScript test adapters.
- Python 3 for Python tooling and tests.
- A terminal with true-color and Nerd Font support.

Useful optional tools:

- [Yazi](https://yazi-rs.github.io/) for file management.
- [lazygit](https://github.com/jesseduffield/lazygit) for LazyVim's Git UI.
- [OpenCode v2](https://opencode.ai/) for the embedded AI agent.
- [llama.cpp](https://github.com/ggml-org/llama.cpp) for local inline
  completion.
- A JDK 17 or newer for SonarQube for IDE; the language server is a JVM
  process. `brew install --cask temurin@21` or `brew install openjdk@21`.
- `pytest`, `vitest`, or `jest` installed in the projects that use them.
- `deno`, `node`, and `python3` for SnipRun and Iron REPL workflows.
- A Rust toolchain to build SnipRun on macOS.

Mason installs most language servers, formatters, linters, and debug adapters
when their corresponding LazyVim extras are active.

## Installation

On macOS, Homebrew can install the main external dependencies:

```bash
brew install neovim git ripgrep fd node python yazi lazygit llama.cpp
```

Install a Nerd Font separately and select it in the terminal application. Some
plugins use Nerd Font glyphs for signs, menus, and status information.

Back up any existing Neovim configuration, then clone this repository as the
Neovim configuration directory:

```bash
mv ~/.config/nvim ~/.config/nvim.backup
git clone https://github.com/pertrai1/my-lazy-vim.git ~/.config/nvim
nvim
```

The first launch bootstraps `lazy.nvim` and installs the configured plugins.
Use these commands inside Neovim if anything needs attention:

```vim
:Lazy
:Mason
:checkhealth
```

## Everyday navigation

| Key | Action |
| --- | --- |
| `<leader><space>` | Smart file picker |
| `<leader>sg` | Find tracked Git files |
| `<leader>sG` | Git status picker |
| `<leader>sd` | Workspace diagnostics |
| `<leader>sD` | Current-buffer diagnostics |
| `<leader>sc` | Search this Neovim configuration |
| `<leader>s:` | Command history |
| `<leader>s/` | Search history |
| `<C-h/j/k/l>` | Move across Neovim splits or tmux panes |
| `<A-h/j/k/l>` | Resize the current split |
| `<C-d>` / `<C-u>` | Scroll while keeping the cursor centered |
| `w`, `e`, `b` | Subword-aware motion across camelCase and snake_case |
| `zR` / `zM` | Open or close all folds |
| `zK` | Preview a fold, falling back to LSP hover |
| `<leader>j` | Structurally split or join a syntax node |
| `<C-s>` | Save from normal, insert, or visual mode |

Use `<leader>hk` to browse all global mappings and `<leader>hb` for mappings
specific to the current buffer.

## Code intelligence and editing

LSP inlay hints are enabled for TypeScript, JavaScript, and Lua. Diagnostics
are rendered inline at the cursor without duplicating Neovim's default virtual
text.

| Key | Action |
| --- | --- |
| `gr` | Find references |
| `gI` | Find implementations |
| `gy` | Find type definitions |
| `]d` / `[d` | Next or previous diagnostic |
| `<leader>cr` | Rename with live preview |
| `<leader>co` | Organize imports |
| `<leader>cE` | Apply all ESLint fixes |
| `<leader>cF` | Apply all source fixes |
| `<leader>cq` | Put diagnostics in quickfix |
| `<leader>cl` | Put diagnostics in the location list |
| `ga` | Change text case |
| `gA` | Change case through an LSP rename |
| `<leader>Rs` | Select a refactoring |
| `<leader>Ri` | Inline a variable |
| `<leader>Rf` | Extract a function |
| `<leader>Rx` | Extract a variable |
| `<leader>P{motion}` | Insert a language-aware debug print |

Visual-mode `J` and `K` move selected lines. `<leader>yp` pastes without
replacing the current register, and `<leader>yd` deletes into the black-hole
register.

## Tests

Neotest discovers Vitest, Jest, and Python tests and displays their state
directly in the buffer. Test mappings use uppercase `T` so the lowercase
`<leader>t` namespace remains available for terminals.

| Key | Action |
| --- | --- |
| `<leader>Tn` | Run the nearest test |
| `<leader>Tf` | Run the current test file |
| `<leader>Ta` | Run all tests from the working directory |
| `<leader>Tl` | Repeat the last test |
| `<leader>Td` | Debug the nearest test with DAP |
| `<leader>Ts` | Toggle the test summary |
| `<leader>To` | Show output for the selected test |
| `<leader>TO` | Toggle the output panel |
| `<leader>Tw` | Watch the current test file |
| `<leader>Tx` | Stop the active test |

Neotest uses the project's own test dependencies. Install the relevant runner
inside the project, for example:

```bash
npm install --save-dev vitest
python3 -m pip install pytest
```

## Code quality

Three tools cover analysis, coverage, and duplication. All of them work in any
repository; anything project-specific lives in the repository itself rather
than in this configuration. See [CODE-QUALITY.md](CODE-QUALITY.md) for the
per-repository files, setup steps, and design notes.

### SonarQube for IDE

Runs the SonarLint language server for JavaScript, TypeScript, Python, and
HTML. In Connected Mode it uses the rules, quality profile, and issue status
from a SonarQube Server or SonarQube Cloud project. Without a binding it still
runs standalone with default rules.

| Key | Action |
| --- | --- |
| `<leader>csi` | Install the SonarQube language server |
| `<leader>csc` | Show Connected Mode status for this repository |
| `<leader>csr` | List all active rules |

Diagnostics are prefixed with Sonar's own severity, for example
`[MEDIUM] Remove this useless assignment`, because LSP has only four severity
levels and every Sonar issue would otherwise arrive as a plain warning.
`HIGH` and `BLOCKER` are raised to error.

Run `<leader>csc` first whenever something looks wrong; it reports the resolved
binding and whether the language server is actually running.

### Coverage

Line coverage is read from whatever report the project's test tooling already
writes, and is shown in the sign column: green for covered, red for uncovered,
purple for partial. The report loads automatically when a supported file is
opened in a repository that has one.

| Key | Action |
| --- | --- |
| `<leader>Tc` | Load the report and show the gutter |
| `<leader>Tu` | Toggle the gutter |
| `<leader>TC` | Per-file coverage summary |

Generate the report with the project's own tooling first, for example
`npm run test:coverage`, `go test -coverprofile=coverage.out`, or
`pytest --cov`.

Coverage never comes from SonarQube. SonarQube for IDE does not report
coverage at all, so these numbers are always local.

## Validation pipelines

Overseer now discovers project-local validation tasks so LLM-produced changes can
be checked with repeatable commands instead of ad-hoc terminal history. It will
surface tasks for repositories that expose any of these checks:

- `openspec/` → `npx @fission-ai/openspec validate --all --no-interactive`
- `package.json` scripts such as `lint`, `typecheck`, `test`, or `jscpd`
- Python repositories with explicit pytest configuration or dependencies
- `./.agents/bin/verify` when agent-directives generated it

Overseer also creates a combined `Validation: all` pipeline. It runs the
available checks sequentially, but it is fail-fast because Overseer's
orchestrator stops when an earlier validation fails or is canceled.

| Key | Action |
| --- | --- |
| `<leader>rV` | Run the combined validation pipeline for the current project |
| `<leader>rt` | Choose any task manually, including individual validation steps |
| `<leader>rv` | Open the task list/output pane |

These tasks are project-aware, so different repositories can expose different
validation menus without changing this Neovim config.

### Duplicate code

`jscpd` scans the repository for copy/paste duplication and puts the results in
the quickfix list, so `]q` and `[q` walk between duplicate blocks.

| Key | Action |
| --- | --- |
| `<leader>cu` | Scan code; prose and configuration are excluded |
| `<leader>cU` | Scan everything, including Markdown, YAML, and JSON |

`:Jscpd` and `:JscpdAll` accept a minimum token count, for example `:Jscpd 100`
to see only substantial clones. The scan uses a project-local `jscpd` when one
is installed and otherwise falls back to `npx`, so nothing needs installing.

## Debugging

The DAP UI opens when a debug session starts and closes when it exits.
JavaScript and TypeScript use the Mason-managed JS debug adapter.

| Key | Action |
| --- | --- |
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Set a conditional breakpoint |
| `<leader>dc` | Start or continue |
| `<leader>dC` | Run to cursor |
| `<leader>di` | Step into |
| `<leader>dO` | Step over |
| `<leader>do` | Step out |
| `<leader>dt` | Terminate |
| `<leader>du` | Toggle DAP UI |
| `<leader>de` | Evaluate expression or selection |
| `<leader>dr` | Toggle DAP REPL |

For a test, `<leader>Td` is normally the fastest entry point.

## Terminals and REPLs

| Key | Action |
| --- | --- |
| `<C-\>` | Toggle the horizontal shell |
| `<leader>tt` | Toggle the shell terminal |
| `<leader>tv` | Toggle a vertical terminal |
| `<leader>tf` | Toggle a floating terminal |
| `<leader>tl` | Toggle the logs terminal |
| `<leader>tr` | Toggle the general REPL terminal |
| `<leader>rs` | Open the language REPL |
| `<leader>rS` | Restart the language REPL |
| `<leader>rl` | Send the current line to the REPL |
| `<leader>rf` | Send the current file |
| `<leader>rc` | Send a motion or visual selection |
| `<leader>rr` | Execute code with SnipRun |

Iron uses `node` for JavaScript, `python3` for Python, and `zsh` for shell
buffers.

## AI workflow

The AI tools have deliberately separate responsibilities:

- OpenCode is the interactive agent for explanations, repository exploration,
  implementation, debugging, and multi-file work.
- Minuet provides small, manually requested inline completions.
- llama.cpp runs the inline model locally, so source code does not need to be
  sent to a completion service.

### OpenCode

Install and authenticate the OpenCode v2 CLI before using the embedded
interface. The Neovim integration tracks the plugin's `main` branch, which
supports OpenCode v2.
Provider and Codex authentication are managed by OpenCode rather than this
Neovim configuration.

| Key | Action |
| --- | --- |
| `<leader>ot` | Toggle the OpenCode TUI in a right-hand terminal |
| `<leader>oa` | Ask about the cursor or visual selection |
| `<leader>o+` | Open Ask with the current buffer or selection as context |
| `<leader>oe` | Send an explanation prompt about the current code |
| `<leader>os` | Select an OpenCode prompt or registered command |

OpenCode v2's Neovim API can send prompts and run registered commands, but it
does not expose controls for creating sessions, appending to the TUI's prompt,
or scrolling its messages. Use the OpenCode TUI (`<leader>ot`) for those actions.

### Local inline completion

The recommended model is Qwen2.5-Coder 1.5B Q8_0. It is small, specialized
for code, and supports fill-in-the-middle completion.

Start the model on the endpoint expected by Minuet:

```bash
llama-server \
  -hf ggml-org/Qwen2.5-Coder-1.5B-Q8_0-GGUF \
  --port 8012 \
  --ctx-size 4096 \
  --cache-reuse 256 \
  --n-gpu-layers all \
  --flash-attn on
```

The first launch downloads the model into llama.cpp's Hugging Face cache.
Confirm that the server is ready:

```bash
curl http://127.0.0.1:8012/v1/models
```

Press `<A-y>` in Insert mode to request a completion. Completion is
manual-first by design, preventing inference on every keystroke. Minuet sends
one request with 512 tokens of surrounding context and requests at most 56 new
tokens. Increase its context to 1024 only if the server remains comfortably
responsive.

To run the server without occupying a terminal:

```bash
mkdir -p ~/Library/Logs/llama.cpp

nohup llama-server \
  -hf ggml-org/Qwen2.5-Coder-1.5B-Q8_0-GGUF \
  --port 8012 \
  --ctx-size 4096 \
  --cache-reuse 256 \
  --n-gpu-layers all \
  --flash-attn on \
  > ~/Library/Logs/llama.cpp/inline.log 2>&1 &
```

Inspect or stop the background server:

```bash
tail -f ~/Library/Logs/llama.cpp/inline.log
pkill -f "llama-server.*--port 8012"
```

## Tasks and repeatable commands

Overseer gives project commands a first-class home inside Neovim. Use it for
long-running dev servers, repeatable build steps, lint commands, or any custom
task templates that belong to a repository.

| Key | Action |
| --- | --- |
| `<leader>rt` | Run a task |
| `<leader>rj` | Select a task action |
| `<leader>rR` | Rerun the most recent task |
| `<leader>rv` | Toggle the task list at the bottom |

## Files, Git, and project navigation

| Key | Action |
| --- | --- |
| `<leader>z` | Open Yazi at the current file |
| `<leader>zr` | Resume the last Yazi session |
| `<leader>cw` | Open Yazi in the working directory |
| `<leader>ma` | Mark the current file |
| `<leader>mm` | Open the marked-files menu |
| `<leader>mj` / `<leader>mk` | Next or previous marked file |
| `<leader>m1` ... `<leader>m4` | Jump to a specific marked file |
| `<leader>gdd` | Open Diffview |
| `<leader>gdc` | Close Diffview |
| `<leader>gdh` | Show history for the current file |
| `<leader>gdH` | Show branch history |

LazyVim's Snacks explorer, Git commands, and pickers remain available alongside
these custom mappings.

## Markdown and snippets

- `<leader>mv` toggles rendered Markdown through Markview.
- `<leader>Sa` creates a VS Code-style snippet.
- `<leader>Se` edits an existing snippet.

Personal snippets are stored under the Neovim configuration directory. If a
newly created snippet does not appear in completion, verify that the custom
snippet directory is registered with Blink.

## Configuration layout

- `lua/config` contains editor options, global mappings, autocommands, startup,
  and compatibility shims.
- `lua/plugins` contains one focused Lazy plugin specification per feature.
- `lazyvim.json` selects official LazyVim extras.
- `lazy-lock.json` pins plugin revisions for reproducible installations.

Add new behavior as a focused plugin specification instead of editing
LazyVim's installed files. Local configuration is merged after LazyVim's
defaults.

## Maintenance

Useful commands:

```vim
:Lazy check
:Lazy update
:Lazy restore
:Lazy profile
:Mason
:MasonUpdate
:checkhealth
```

- Commit `lazy-lock.json` whenever intentionally changing plugin versions.
- Use `:Lazy restore` to return installed plugins to the committed lockfile.
- Run `:Lazy profile` before adding eager startup dependencies.
- Run `:checkhealth` after upgrading Neovim, language runtimes, or Treesitter.
- Keep external project dependencies such as Vitest and pytest in their
  respective projects rather than installing them through this configuration.

## Troubleshooting

### Minuet returns no completion

1. Confirm `llama-server` is listening on port `8012`.
2. Check `curl http://127.0.0.1:8012/v1/models`.
3. Confirm the loaded model supports Qwen-style FIM tokens.
4. Inspect `~/Library/Logs/llama.cpp/inline.log` when running in the background.
5. Open `:Lazy` and confirm `minuet-ai.nvim` loaded after entering Insert mode.

### Tests are not discovered

1. Confirm the matching test runner is installed in the project.
2. Open a test file and toggle `<leader>Ts`.
3. Check the project root and test filename conventions.
4. Inspect `:checkhealth neotest`.

### Language tooling is missing

Open `:Mason`, verify the relevant executable exists, and run `:LspInfo` from
the affected buffer. Project-local formatters and linters take precedence when
available.

### SonarQube exits with code 1

The language server is a JVM process and no working JDK was found. macOS ships
a `/usr/bin/java` stub that exists but fails on any real invocation, which is
why the failure surfaces as a bare exit code. Install a JDK 17 or newer; the
configuration finds it even when Homebrew keeps it off `PATH`.

### SonarQube runs but does not use the server's rules

Run `<leader>csc`. If it reports `standalone`, the repository has no resolvable
binding. If it reports `connected` but the language server is not running, the
problem is the JDK rather than the binding. See
[CODE-QUALITY.md](CODE-QUALITY.md).

### The coverage gutter is empty

Either no report exists yet, or every line is covered. Coverage marks covered
lines as well as uncovered ones, so a fully covered file shows green rather
than nothing. Run the project's coverage command, then `<leader>Tc`. Test files
themselves are usually absent from coverage reports and will never show marks.

### A shortcut is unclear or appears overridden

Use `<leader>hk` for the global WhichKey view or run:

```vim
:verbose nmap <key>
```

The output shows which configuration or plugin last defined the mapping.
