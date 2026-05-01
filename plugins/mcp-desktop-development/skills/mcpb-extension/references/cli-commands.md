# mcpb CLI Reference

Canonical source: `modelcontextprotocol/mcpb/CLI.md`. Install with `npm install -g @anthropic-ai/mcpb`.

## `mcpb init [directory]`

Interactive scaffold. Prompts for `name`, `version`, `description`, `author`, server `type`, `entry_point`, optional tools, and `compatibility`. Writes `manifest.json` into the chosen directory (default: cwd).

```bash
mcpb init                    # scaffold in cwd
mcpb init my-extension       # scaffold in subdir (creates if missing)
```

After init, implement the server code, install runtime deps, and proceed to `validate` → `pack`.

## `mcpb validate <path>`

Validates a manifest against the JSON Schema for its declared `manifest_version`. Accepts either a manifest file or a directory containing one.

```bash
mcpb validate manifest.json
mcpb validate ./my-extension          # equivalent: looks for manifest.json
```

Exit code `0` on success, non-zero on schema violations. Errors include JSON path + reason.

## `mcpb pack <directory> [output]`

Validates the manifest, then ZIPs the directory into a `.mcpb` file with maximum compression. Default output is `<dirname>.mcpb` next to the source.

```bash
mcpb pack .                                    # → ./directory-name.mcpb
mcpb pack ./my-extension out/extension.mcpb    # explicit output path
mcpb pack . --manifest custom-manifest.json    # use a non-default manifest
```

Auto-excluded files (always):

- `.git/`, `.gitignore`
- `.DS_Store`, `Thumbs.db`
- `package-lock.json`, `yarn.lock`
- `*.log`
- `.npm/`, `.yarn/`
- `.env.local`, `.env.*.local`
- `node_modules/.cache/`, `node_modules/.bin/`
- `*.map`

Add custom exclusions with `.mcpbignore` at the bundle root (gitignore syntax). Useful entries: `.venv/`, `__pycache__/`, `*.pyc`, `.pytest_cache/`, `dist/`, `build/`, test fixtures.

`pack` aborts if validation fails — no need to call `validate` separately in CI.

## `mcpb sign <mcpb-file>`

Signs the bundle with PKCS#7 (CMS, DER-encoded), SHA-256 digest. The signature is detached and stored in the ZIP's End-of-Central-Directory comment, framed by `MCPB_SIG_V1` / `MCPB_SIG_END` markers — the underlying ZIP stays a valid ZIP.

Flags:

| Flag | Default | Purpose |
|------|---------|---------|
| `--cert`, `-c` | `cert.pem` | X.509 leaf certificate (PEM) |
| `--key`, `-k`  | `key.pem`  | Matching private key (PEM) |
| `--intermediate`, `-i` | — | Intermediate certs (repeatable) for chain to a CA root |
| `--self-signed` | — | Generate a self-signed cert/key on the fly if the cert path is missing |

```bash
# Local dev — auto-generate a self-signed cert
mcpb sign my-extension.mcpb --self-signed

# Production — provide a real cert chain
mcpb sign my-extension.mcpb \
  --cert prod-leaf.pem \
  --key  prod-leaf.key \
  --intermediate intermediate-1.pem \
  --intermediate intermediate-2.pem
```

A previously-signed bundle has its signature replaced (no need to `unsign` first).

## `mcpb verify <mcpb-file>`

Verifies the PKCS#7 signature against the bundle contents, prints certificate details, and warns if self-signed.

```bash
mcpb verify my-extension.mcpb
```

Output includes:

- Signature validity (pass/fail)
- Certificate subject + issuer
- Validity dates (`notBefore` / `notAfter`)
- SHA-256 fingerprint
- Self-signed warning (if leaf == issuer)

Exit code `0` only when the signature is valid.

## `mcpb info <mcpb-file>`

Inspect a bundle without verifying signatures. Reports:

- File size
- Whether a signature block is present
- Certificate subject/issuer/dates if signed

```bash
mcpb info my-extension.mcpb
```

## `mcpb unsign <mcpb-file>`

Strips the signature block from the EOCD comment in place. Used during dev to clear a stale signature before re-signing, or to ship an unsigned build.

```bash
mcpb unsign my-extension.mcpb
```

## `mcpb unpack <mcpb-file> [directory]`

Extracts the ZIP contents into a directory. Default output is the bundle name without `.mcpb` extension.

```bash
mcpb unpack my-extension.mcpb              # → ./my-extension/
mcpb unpack my-extension.mcpb ./out-dir
```

The signature block (if any) lives in the ZIP comment, not as a file — extracting an unsigned tree is identical to extracting a signed one.

## Common workflows

### First-time scaffold

```bash
mkdir my-ext && cd my-ext
mcpb init
# implement server/index.js, package.json, etc.
npm ci --omit=dev
mcpb validate manifest.json
mcpb pack . my-ext.mcpb
```

### Iterative dev loop

```bash
# after editing server code:
mcpb pack . my-ext.mcpb && mcpb info my-ext.mcpb
# install in host (Claude Desktop) and test
```

### Release with self-signed (dev distribution)

```bash
mcpb pack . my-ext.mcpb
mcpb sign my-ext.mcpb --self-signed
mcpb verify my-ext.mcpb
```

### Release with a real cert chain (production)

```bash
mcpb pack . my-ext.mcpb
mcpb sign my-ext.mcpb \
  --cert  $RELEASE_CERTS/leaf.pem \
  --key   $RELEASE_CERTS/leaf.key \
  --intermediate $RELEASE_CERTS/intermediate.pem
mcpb verify my-ext.mcpb
mcpb info my-ext.mcpb
```

## Exit codes

All commands follow standard conventions:

- `0` — success
- non-zero — validation failure, schema mismatch, signature failure, or I/O error

In CI, run `mcpb pack` and `mcpb verify` after signing — both exit non-zero on any problem.
