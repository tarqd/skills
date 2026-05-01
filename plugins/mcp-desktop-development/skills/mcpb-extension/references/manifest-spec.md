# Manifest Specification

Field-by-field reference for `manifest.json`. Canonical source: `modelcontextprotocol/mcpb/MANIFEST.md`. JSON Schema: `modelcontextprotocol/mcpb/schemas/mcpb-manifest-latest.schema.json`.

## Versioning

`manifest_version` selects the spec revision the bundle targets:

- `"0.1"` — Original; some examples in the repo still use it.
- `"0.2"` — Added refinements (icons array, etc.).
- `"0.3"` — **Current default.** Use this unless UV is required.
- `"0.4"` — Adds `server.type: "uv"` (host-managed Python via UV).

Hosts validate against the version declared. Always validate locally with `mcpb validate manifest.json` before packing.

## Required top-level fields

| Field | Type | Notes |
|-------|------|-------|
| `manifest_version` | string | Spec version, e.g. `"0.3"` |
| `name` | string | Machine identifier; lowercase, hyphenated |
| `version` | string | Semantic version |
| `description` | string | One-line summary; localizable |
| `author` | object | `{ name, email?, url? }`; localizable |
| `server` | object | See "Server" below |

## Optional top-level fields

| Field | Type | Notes |
|-------|------|-------|
| `display_name` | string | UI title; localizable |
| `long_description` | string | Markdown; localizable |
| `icon` | string | Path to a single icon (legacy single-icon form) |
| `icons` | array | Multi-size/theme icon objects (preferred) |
| `repository` | object | `{ type, url }` — e.g. `{ "type": "git", "url": "..." }` |
| `homepage` | string (URL) | |
| `documentation` | string (URL) | |
| `support` | string (URL) | |
| `keywords` | string[] | Tags for discovery |
| `license` | string | SPDX identifier |
| `privacy_policies` | string[] | URLs — required if the server contacts third-party APIs |
| `tools` | array | Static tool declarations (see below) |
| `prompts` | array | Static prompt declarations (see below) |
| `tools_generated` | boolean | `true` if tools are emitted at runtime instead of declared |
| `prompts_generated` | boolean | Same idea for prompts |
| `compatibility` | object | Version/platform constraints |
| `user_config` | object | User-prompted configuration (see below) |
| `localization` | object | External locale resources |
| `_meta` | object | Platform-specific extension data |

## `server`

```json
{
  "type": "node | python | uv | binary",
  "entry_point": "server/index.js",
  "mcp_config": { ... }
}
```

- `type` (required) — runtime selector. See `server-types.md` for per-type bundling rules.
- `entry_point` (required) — relative path inside the bundle to the script/binary.
- `mcp_config` (required) — how the host launches the server.

### `mcp_config`

```json
{
  "command": "node",
  "args": ["${__dirname}/server/index.js", "--port=${user_config.port}"],
  "env": {
    "API_KEY": "${user_config.api_key}",
    "LOG_LEVEL": "${user_config.verbose_logging}"
  },
  "platform_overrides": {
    "win32": { "command": "node.exe", "args": [...] },
    "darwin": { "args": [...] },
    "linux":  { "args": [...] }
  }
}
```

- `command` — executable name; resolved via `PATH` unless absolute.
- `args` — argv after `command`. Variable substitution applies.
- `env` — environment variables. Variable substitution applies.
- `platform_overrides` — keys: `win32`, `darwin`, `linux`. Override any of `command`/`args`/`env` per OS.

### Variable substitution

Tokens valid inside `args`, `env`, and (selectively) `command`:

| Token | Resolves to |
|-------|-------------|
| `${__dirname}` | Absolute path to the extracted bundle root |
| `${HOME}` | User home directory |
| `${DESKTOP}` | User Desktop |
| `${DOCUMENTS}` | User Documents |
| `${DOWNLOADS}` | User Downloads |
| `${user_config.KEY}` | Value the user provided for `user_config.KEY` |
| `${pathSeparator}` / `${/}` | `/` on POSIX, `\` on Windows |

For `user_config` entries with `"multiple": true`, the substituted value expands into **multiple** separate argv entries when used in `args` — do not wrap in a single string.

## `user_config`

Map of config key → field schema. The host renders a settings UI from this map and substitutes values at launch.

```json
"user_config": {
  "api_key": {
    "type": "string",
    "title": "API Key",
    "description": "Your service API key",
    "required": true,
    "sensitive": true
  },
  "max_results": {
    "type": "number",
    "title": "Max results",
    "default": 50,
    "min": 1,
    "max": 1000
  },
  "verbose_logging": {
    "type": "boolean",
    "title": "Verbose logging",
    "default": false
  },
  "workspace_directory": {
    "type": "directory",
    "title": "Workspace",
    "default": "${HOME}/workspace"
  },
  "config_file": {
    "type": "file",
    "title": "Config file",
    "required": false
  },
  "allowed_directories": {
    "type": "directory",
    "title": "Allowed directories",
    "multiple": true,
    "default": ["${HOME}/Documents"]
  }
}
```

Field schema keys (`type`, `title`, `description` are **required on every entry** — schema validation fails otherwise):

| Key | Required | Applies to | Notes |
|-----|----------|-----------|-------|
| `type` | ✓ | all | One of `string`, `number`, `boolean`, `directory`, `file` |
| `title` | ✓ | all | Label in the settings UI |
| `description` | ✓ | all | Help text |
| `required` |   | all | If `true` and unset at launch, host blocks startup |
| `default` |   | all | Pre-filled value (or array if `multiple`) |
| `sensitive` |   | string | Mask in UI; treat as secret |
| `min` / `max` |   | number | Bounds |
| `multiple` |   | directory, file, string | Expands into multiple argv entries when interpolated |

## `tools` / `prompts`

Static declarations let hosts show capabilities pre-install.

```json
"tools": [
  { "name": "get_current_time", "description": "Returns the current time" }
],
"prompts": [
  {
    "name": "summarize",
    "description": "Summarize input text",
    "arguments": ["text", "max_words"],
    "text": "Summarize the following in ${arguments.max_words} words:\n${arguments.text}"
  }
]
```

If tools/prompts are dynamic (registered at runtime), set `"tools_generated": true` / `"prompts_generated": true` and omit the corresponding array.

## `compatibility`

```json
"compatibility": {
  "claude_desktop": ">=0.10.0",
  "platforms": ["darwin", "win32", "linux"],
  "runtimes": {
    "node": ">=18.0.0",
    "python": ">=3.10"
  }
}
```

All sub-fields optional. If omitted, the bundle declares "runs anywhere" — set `platforms` explicitly when shipping `binary` server types.

## `icons`

```json
"icons": [
  { "src": "icons/icon-256.png", "sizes": ["256x256"], "theme": "any" },
  { "src": "icons/icon-dark.png", "sizes": ["256x256"], "theme": "dark" }
]
```

- `src` — relative path inside bundle.
- `sizes` — array of `WxH` strings.
- `theme` — `light` | `dark` | `any` (default).

## `localization`

```json
"localization": {
  "default_locale": "en",
  "resources": "locales/${locale}.json"
}
```

`${locale}` is substituted by the host. Clients fall back narrowly → broadly (`es-UY` → `es-MX` → `es` → default).

Localizable fields: `description`, `display_name`, `long_description`, `author.name`, `author.email`, `author.url`, plus `title`/`description` inside `user_config` and `tools`/`prompts`.

## `_meta`

Free-form object for platform-specific data. Known consumers:

```json
"_meta": {
  "windows": {
    "package_family_name": "Publisher.Name_abc123"
  }
}
```

Unrecognized keys are ignored by hosts.

## Validation tips

- `mcpb validate <path>` accepts either a directory (containing `manifest.json`) or a manifest file directly.
- The validator enforces the JSON Schema for the declared `manifest_version`. Mismatched versions emit clear errors.
- `mcpb pack` runs validation first and aborts on errors — there's no need to re-run `validate` separately in CI if the next step is `pack`.
- The validator also checks that referenced asset files exist on disk (e.g. `icon`, `icons[].src`). Validating a manifest that points at a missing `icon.png` fails with `Icon file not found at path: ...` even though the schema itself is correct. Either remove the field or place the file before validating.
- Every entry under `user_config` must include `type`, `title`, **and** `description` — omitting `description` is the most common schema failure.
