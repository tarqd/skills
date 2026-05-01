# Server Types

Each `server.type` value imposes different bundling, runtime, and distribution rules.

## `node` — recommended default

Why: Node ships with Claude Desktop, so end users don't need a runtime install. Bundles are self-contained.

### Layout

```
my-ext.mcpb
├── manifest.json
├── package.json
├── server/
│   └── index.js
└── node_modules/        # production deps, fully bundled
```

### Build steps

```bash
npm ci --omit=dev        # install only production deps
mcpb pack . my-ext.mcpb
```

### Manifest

```json
{
  "manifest_version": "0.3",
  "server": {
    "type": "node",
    "entry_point": "server/index.js",
    "mcp_config": {
      "command": "node",
      "args": ["${__dirname}/server/index.js"]
    }
  }
}
```

### Pitfalls

- Forgetting `--omit=dev` ships TypeScript, test runners, etc.
- Leaving `node_modules/.cache` or `.bin` is fine — `pack` excludes them automatically.
- Native modules (`better-sqlite3`, `node-canvas`, etc.) compile per-platform; either ship platform-specific bundles or use a pure-JS alternative.

## `uv` — modern Python (manifest 0.4+)

Why: The host manages Python and dependencies via [UV](https://docs.astral.sh/uv/). Bundles are tiny (~100 KB) because no venv ships.

### Layout

```
my-ext.mcpb
├── manifest.json
├── pyproject.toml
├── .mcpbignore           # excludes .venv/, __pycache__/, etc.
└── src/
    └── server.py
```

### Manifest

```json
{
  "manifest_version": "0.4",
  "server": {
    "type": "uv",
    "entry_point": "src/server.py",
    "mcp_config": {
      "command": "uv",
      "args": [
        "run",
        "--project", "${__dirname}",
        "python", "${__dirname}/src/server.py"
      ]
    }
  }
}
```

### `.mcpbignore`

```
.venv/
__pycache__/
*.pyc
.pytest_cache/
.mypy_cache/
dist/
build/
```

### Pitfalls

- Hosts must have UV installed; declare this implicitly via `manifest_version: "0.4"`.
- Pin Python in `pyproject.toml` (`requires-python = ">=3.10"`) — UV honors it.

## `python` — legacy bundled Python

Why: When UV isn't available or the host doesn't support it. Ship dependencies in-bundle.

### Layout

```
my-ext.mcpb
├── manifest.json
├── server/
│   ├── main.py
│   ├── lib/              # site-packages of bundled deps
│   └── venv/             # OR a full venv (heavier, more portable)
└── requirements.txt
```

### Build steps (lib approach)

```bash
pip install -r requirements.txt --target server/lib
mcpb pack . my-ext.mcpb
```

### Manifest

```json
{
  "manifest_version": "0.3",
  "server": {
    "type": "python",
    "entry_point": "server/main.py",
    "mcp_config": {
      "command": "python3",
      "args": ["${__dirname}/server/main.py"],
      "env": {
        "PYTHONPATH": "${__dirname}/server/lib"
      }
    }
  }
}
```

### Pitfalls

- Bundles get heavy (10–50 MB common). UV is preferable when available.
- Cross-platform native wheels: `pip install` with `--platform` to ship the right wheels per-OS, or ship multiple bundles.
- Set `PYTHONPATH` in `env` — relying on `sys.path.insert` from inside the script works but is fragile.

## `binary` — compiled standalone

Why: Rust, Go, Zig, C++, etc. — everything embedded into a single executable.

### Layout

```
my-ext.mcpb
├── manifest.json
└── bin/
    ├── server-darwin-arm64
    ├── server-darwin-x64
    ├── server-win32-x64.exe
    └── server-linux-x64
```

### Manifest with `platform_overrides`

```json
{
  "manifest_version": "0.3",
  "compatibility": {
    "platforms": ["darwin", "win32", "linux"]
  },
  "server": {
    "type": "binary",
    "entry_point": "bin/server",
    "mcp_config": {
      "command": "${__dirname}/bin/server",
      "platform_overrides": {
        "darwin": { "command": "${__dirname}/bin/server-darwin-arm64" },
        "win32":  { "command": "${__dirname}/bin/server-win32-x64.exe" },
        "linux":  { "command": "${__dirname}/bin/server-linux-x64" }
      }
    }
  }
}
```

### Pitfalls

- ZIP doesn't preserve execute bits on Windows-created archives. Hosts mark binary `command` paths executable on extract, but `args` paths are not chmod'd — keep the binary as `command`, not as an `args` entry.
- Always set `compatibility.platforms` for binary bundles. Without it, the bundle advertises support for OSes it can't run on.
- Per-arch on macOS: ship a universal binary (`lipo`-merged) or branch on architecture in `platform_overrides` (use a wrapper script if needed).

## Decision matrix

| Need | Pick |
|------|------|
| Default for new bundles | `node` |
| Modern Python, small bundle | `uv` (manifest 0.4) |
| Python on hosts without UV | `python` |
| Native performance / no runtime dep | `binary` |
| Mixed: TS server + Rust helper | `node` with the helper bundled under `bin/` and spawned via `child_process` |
