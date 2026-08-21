# Code quality tooling

Reference for the SonarQube, coverage, and duplication setup: which files a
repository needs, where credentials live, and why some of it is built the way
it is. The keymaps are in [README.md](README.md).

## Quick reference

| Thing | Location | Committed? |
| --- | --- | --- |
| Sonar connections and tokens | `~/.local/share/nvim/sonarqube/connections.json` | No, never |
| Sonar per-repository binding | `<repo>/.sonarlint.json` | Yes, safe |
| jscpd per-repository overrides | `<repo>/.jscpd.json` | Yes, optional |
| Coverage report | Project-specific, see below | No, gitignored |

Nothing here is configured per repository inside this Neovim configuration.
Each repository carries its own settings so the same setup works everywhere.

## SonarQube Connected Mode

Connected Mode is split into two files so credentials never live inside a
project repository.

### 1. Connections — secret, one file, outside every repository

`~/.local/share/nvim/sonarqube/connections.json`, mode `600`:

```json
{
  "work": {
    "serverUrl": "https://sonarqube.corp.example.com",
    "tokenCmd": ["security", "find-generic-password", "-w", "-s", "sonar-work"]
  },
  "cloud": {
    "organizationKey": "my-org",
    "tokenCmd": ["security", "find-generic-password", "-w", "-s", "sonar-cloud"]
  }
}
```

Each entry names exactly one of:

- `serverUrl` — a self-hosted SonarQube Server.
- `organizationKey` — SonarQube Cloud. Add `"region": "US"` for `sonarqube.us`;
  the default is EU (`sonarcloud.io`).

...plus exactly one token source:

- `token` — the literal token. Simplest, but plaintext on disk.
- `tokenCmd` — an argv array that prints the token. Preferred.
- `tokenEnv` — the name of an environment variable holding the token.

Store a token in the macOS Keychain without putting it in shell history:

```bash
security add-generic-password -a "$USER" -s sonar-cloud-myorg -w
```

Generate the token itself under **My Account → Access Tokens**. It must be a
**User Token**; project or global *analysis* tokens authenticate but cannot
read back rules and issues, so Connected Mode silently fails to sync.

### 2. Binding — no secrets, one per repository

`<repo>/.sonarlint.json`:

```json
{
  "connection": "cloud",
  "projectKey": "my-org_my-service"
}
```

It only *names* a connection, so it is safe to commit and works for anyone who
clones the repository and has their own connection of that name. Repositories
on different servers name different connections.

`projectKey` must match the server exactly. If the repository has a
`sonar-project.properties`, copy `sonar.projectKey` from it.

Environment variables `SONARQUBE_URL`, `SONARQUBE_TOKEN`, and
`SONARQUBE_PROJECT_KEY` still work, but only as a fallback when a repository
has no `.sonarlint.json`.

### One connection per Neovim session

Only one SonarQube language server runs per session, and every buffer attaches
to the first one started. Editing two differently-bound repositories in one
Neovim means the second is analysed against the first repository's project.
A warning fires when that happens; open the other repository in its own Neovim.

## Coverage

Reports are looked up from the repository root, so running Neovim from a
subdirectory works. The first candidate that exists wins:

| Language | Report |
| --- | --- |
| JavaScript / TypeScript | `coverage/lcov.info` |
| Python | `.coverage`, `coverage.xml` |
| Go | `coverage.out`, `cover.out` |
| Java | `build/reports/jacoco/test/jacocoTestReport.xml`, `target/site/jacoco/jacoco.xml` |
| Ruby | `coverage/coverage.json` |
| PHP | `coverage/cobertura.xml` |
| C# | `TestResults/lcov.info` |
| C / C++ | `report.info`, `coverage.info` |
| Lua | `luacov.report.out` |
| Elixir | `cover/lcov.info` |
| Dart | `coverage/lcov.info` |
| Julia | `lcov.info` |

Rust and Swift resolve their coverage through a command rather than a file and
are left to the plugin's own handling.

Things that look like bugs but are not:

- **Test files show no coverage marks.** Test runners instrument the code under
  test, not the tests themselves, so test files are absent from the report.
- **A fully covered file shows green, not nothing.** "Lines to cover" in
  SonarQube means *coverable* lines, not lines missing coverage.

## Duplicate code

Defaults skip build output, vendor directories, and generated or minified
files across ecosystems, plus prose and configuration formats unless
`<leader>cU` is used.

No built-in list can know which directories a given project vendors. When the
defaults are wrong, commit a `.jscpd.json` at the repository root:

```json
{
  "minTokens": 50,
  "ignore": ["**/js/lib/**", "**/legacy/**"]
}
```

When that file exists it takes over completely — the built-in ignore list and
token threshold are not passed, so the project's own settings win. The status
message shows `[.jscpd.json]` when a project config is in effect.

## SonarQube-side repository settings

These live in the repository's `sonar-project.properties` and affect the server
dashboard rather than Neovim, but they are easy to get wrong.

Co-located tests need `sonar.test.inclusions`, otherwise SonarQube treats test
files as production source, reports them as 0% covered, and counts their shared
skeletons as duplicated code:

```properties
sonar.sources=.
sonar.tests=.
sonar.test.inclusions=**/*.test.ts,**/*.spec.ts,**/*.test.js,**/*.spec.js
```

Coverage also has to be uploaded by CI; the IDE never sends it. For JavaScript
and TypeScript:

```properties
sonar.javascript.lcov.reportPaths=./coverage/lcov.info
```

## Design notes

Non-obvious findings, kept so the reasoning is not lost.

**SonarQube reports neither coverage nor duplication in the IDE.** Its analyzer
ships `NoOpNewCoverage` and `NoOpNewCpdTokens` — deliberate no-op
implementations — and exposes no client methods for either. Both metrics are
computed server-side by the CI scanner. This is why coverage and duplication
are handled by separate tools rather than read from the language server.

**The plugin ignores `setup{ lsp = { settings } }`.** `sonarqube.nvim` starts
the client with its own `sonarqube.lsp.server.settings` table, so Connected
Mode settings have to be written onto that module directly. Passing them
through `setup()` looks correct, appears in `:SonarQubeShowConfig`, and does
nothing.

**Settings alone do not establish Connected Mode.** Before binding a project,
the server requests the credential from the client over
`sonarlint/getTokenForServer`. Without a handler the request goes unanswered
and binding stalls after syncing plugins, with no error. The identifier passed
is `<REGION>_<organizationKey>` for Cloud, for example `EU_my-org`, not the
bare organization key. A handler must always return a value; returning nil
leaves the server waiting forever.

**Sonar's real severity travels in `data.impactSeverity`** as a raw enum
ordinal, because LSP has only four severity levels. Two enums share the range
and the integer alone cannot distinguish them:

| Ordinal | MQR mode (Cloud default) | Standard mode |
| --- | --- | --- |
| 0 | INFO | INFO |
| 1 | LOW | MINOR |
| 2 | MEDIUM | MAJOR |
| 3 | HIGH | CRITICAL |
| 4 | BLOCKER | BLOCKER |

`SEVERITY_MODE` at the top of `lua/plugins/sonarqube.lua` selects the labels.

**Coverage signs are session state.** Nothing appears until the report is
loaded, so an unloaded gutter and a fully-uncovered file look identical. The
configuration loads reports automatically on `FileType` — not `BufReadPost`,
because the plugin dispatches on `vim.bo.filetype`, which is not set yet.

**jscpd's `xcode` reporter is not plain `file:line:col`.** Files tokenised per
embedded block gain a format segment, for example
`docs/TESTING.md:typescript:97:0:`, which is indistinguishable from a path
component by shape. Vim's `errorformat` cannot parse both forms, so output is
parsed in Lua and the ambiguity resolved against the filesystem.

**Knip was evaluated and rejected** for repositories that are collections of
independent files rather than an application. Its reachability model reports
anything unimported as unused, which is meaningless when most files are
intentionally unreachable leaves.

## Verifying a setup

```vim
:SonarQubeConnectedStatus
```

Reports the resolved binding, whether the language server is running, and
whether the connected-mode settings reached it.

Server-side proof that Connected Mode really synced:

```bash
find ~/.sonarlint/storage -name analyzer_config.pb
```

The path contains the connection id and project key, hex-encoded. If
`projects/` is missing and only `plugin_references.pb` exists, the binding
stalled — usually the token.
