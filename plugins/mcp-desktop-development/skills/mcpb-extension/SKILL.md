---
name: mcpb-extension
description: >-
  This skill should be used when the user asks to "build an MCP desktop extension",
  "create a .mcpb bundle", "write a manifest.json for mcpb", "pack an MCP extension",
  "sign a .mcpb file", "validate an MCPB manifest", "use mcpb init/pack/validate/sign/verify",
  "bundle an MCP server for Claude Desktop", or mentions MCPB, .mcpb files,
  manifest_version, mcp_config, user_config, or @anthropic-ai/mcpb. Covers the
  manifest spec, the mcpb CLI, and bundling/signing/validation workflows.
---

# MCP Desktop Extension Development (MCPB)

MCPB is the bundle format for distributing MCP servers as installable desktop extensions (`.mcpb` files). A bundle is a ZIP archive containing a `manifest.json` plus the server code (Node.js, Python, UV-managed Python, or a binary). Hosts like Claude Desktop install bundles with one click and wire user-supplied configuration into the MCP server at launch.

The official tooling lives at `@anthropic-ai/mcpb` (npm). The canonical spec is `MANIFEST.md` in `modelcontextprotocol/mcpb`.

## When to use this skill

Use it whenever the user is creating, editing, validating, packing, signing, or verifying a `.mcpb` extension — including writing or fixing `manifest.json`, choosing a server type, or debugging a bundle that fails to load.

## Quick start

```bash
npm install -g @anthropic-ai/mcpb       # install CLI

mkdir my-extension && cd my-extension
mcpb init                                # interactive manifest scaffold
# ... implement server code ...
mcpb validate manifest.json              # check manifest against schema
mcpb pack . my-extension.mcpb            # validates + zips
mcpb sign my-extension.mcpb --self-signed  # optional
mcpb verify my-extension.mcpb            # confirm signature
mcpb info my-extension.mcpb              # inspect bundle
```

## Manifest essentials

A manifest must declare `manifest_version`, `name`, `version`, `description`, `author`, and `server`. Current spec is `0.3` (use `0.4` only if relying on the UV runtime).

Minimal Node.js example:

```json
{
  "manifest_version": "0.3",
  "name": "my-extension",
  "version": "1.0.0",
  "description": "Does a useful thing",
  "author": { "name": "Jane Doe" },
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

### Server types

| Type | When to choose | Notes |
|------|---------------|-------|
| `node` | **Default recommendation.** | Node ships with Claude Desktop; bundle `node_modules`. |
| `uv` | Modern Python (manifest 0.4+). | Host manages Python + deps; tiny bundles (~100 KB). |
| `python` | Legacy Python with bundled deps. | Bundle into `server/lib/` or `server/venv/`. |
| `binary` | Compiled standalone (Rust, Go, etc.). | Per-platform builds via `platform_overrides`. |

Full server-type details: `references/server-types.md`.

### Variable substitution in `mcp_config`

Use these inside `command`, `args`, and `env`:

- `${__dirname}` — bundle root after extraction
- `${user_config.KEY}` — user-supplied config value
- `${HOME}`, `${DESKTOP}`, `${DOCUMENTS}`, `${DOWNLOADS}` — standard paths
- `${pathSeparator}` / `${/}` — platform path separator

### `user_config` (user-facing settings)

Declare config the host should prompt for. Types: `string`, `number`, `boolean`, `directory`, `file`. Mark secrets with `"sensitive": true`. Arrays with `"multiple": true` expand into separate CLI args when interpolated into `args`.

```json
"user_config": {
  "api_key": { "type": "string", "title": "API Key", "sensitive": true, "required": true },
  "allowed_dirs": { "type": "directory", "multiple": true, "default": ["${HOME}"] }
}
```

Full field reference (including `compatibility`, `tools`, `prompts`, `localization`, `_meta`, `icons`, `privacy_policies`): `references/manifest-spec.md`.

## CLI reference

| Command | Purpose |
|---------|---------|
| `mcpb init [dir]` | Interactive manifest scaffold |
| `mcpb validate <path>` | Validate manifest against JSON schema |
| `mcpb pack <dir> [output]` | Validate + zip into `.mcpb` |
| `mcpb sign <file>` | PKCS#7 sign with X.509 cert |
| `mcpb verify <file>` | Verify signature, show cert info |
| `mcpb info <file>` | Show size, signature status, cert details |
| `mcpb unsign <file>` | Strip signature (dev/testing) |
| `mcpb unpack <file> [dir]` | Extract bundle |

Flags worth knowing: `--cert`/`-c`, `--key`/`-k`, `--intermediate`/`-i`, `--self-signed`, `--manifest <path>`. Full flags + behavior: `references/cli-commands.md`.

## Bundle structure

A `.mcpb` is a plain ZIP whose End-of-Central-Directory comment may carry a detached PKCS#7 signature (markers `MCPB_SIG_V1` / `MCPB_SIG_END`). Unsigned bundles open as normal ZIPs.

Auto-excluded by `pack`: `.git/`, `.DS_Store`, `Thumbs.db`, `package-lock.json`, `yarn.lock`, `*.log`, `.npm/`, `.yarn/`, `.env.local`, `.env.*.local`, `node_modules/.cache/`, `node_modules/.bin/`, `*.map`. Custom exclusions: `.mcpbignore` (gitignore syntax).

Layout deep-dive (per server type, what to commit vs. bundle, signature format): `references/bundling-workflow.md`.

## Working with an existing manifest

When editing or reviewing a manifest:

1. Read the current `manifest.json`.
2. Run `mcpb validate manifest.json` to surface schema errors before guessing.
3. Cross-check fields against `references/manifest-spec.md` — it's organized by field, not by example.
4. For server-type questions, consult `references/server-types.md`.
5. To repack: `mcpb pack . out.mcpb` (validates first; refuses to pack invalid manifests).

## Common pitfalls

- Forgetting `${__dirname}` prefix in `args` paths — the working directory at launch is not the bundle root.
- Bundling Node without running `npm ci --omit=dev` first → ships dev deps and bloats the bundle.
- Python `python` type without a bundled venv/lib → server fails to import.
- Missing `compatibility.platforms` when shipping a binary — the bundle installs on platforms that can't run it.
- Putting secrets in `mcp_config.env` literally instead of `${user_config.api_key}`.
- Running `mcpb sign` without `--self-signed` and without `cert.pem`/`key.pem` present → cryptic OpenSSL error.
- Omitting `description` on a `user_config` entry — schema requires `type`, `title`, **and** `description` on every field.
- Declaring an `icon`/`icons[].src` whose file isn't present at validation time — `mcpb validate` checks asset paths exist on disk, not just the schema.

## Examples

Reference manifests in `examples/`:

- **`manifest-node.json`** — full Node.js manifest with `user_config`, `tools`, `compatibility`
- **`manifest-uv-python.json`** — minimal UV Python manifest (spec 0.4)
- **`manifest-binary.json`** — binary server with `platform_overrides`

These mirror the official `examples/` in `modelcontextprotocol/mcpb` and are safe starting points for new bundles.

## Reference files

- **`references/manifest-spec.md`** — every manifest field, field-by-field
- **`references/cli-commands.md`** — every CLI command and flag, with output samples
- **`references/server-types.md`** — Node vs. Python vs. UV vs. binary; how each is bundled and launched
- **`references/bundling-workflow.md`** — pack/sign/verify internals, `.mcpbignore`, ZIP layout, signature format

## Scripts

- **`scripts/validate-manifest.sh`** — wrapper that runs `mcpb validate` with a clear failure message
- **`scripts/quick-pack.sh`** — pack + self-signed sign + verify in one step (for local dev)

## Authoritative sources

When in doubt, prefer the upstream docs over memory:

- Spec: `modelcontextprotocol/mcpb/MANIFEST.md`
- CLI: `modelcontextprotocol/mcpb/CLI.md`
- JSON Schema: `modelcontextprotocol/mcpb/schemas/mcpb-manifest-latest.schema.json`
- Examples: `modelcontextprotocol/mcpb/examples/`
