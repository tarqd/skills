# Bundling, Signing, and Validation Workflow

Detailed mechanics behind `pack` / `sign` / `verify`. Useful when debugging a bundle the host refuses to load, or when integrating mcpb into CI.

## End-to-end pipeline

```
source tree
    │
    ├──► validate (schema check)
    │
    ├──► pack    (zip, max compression, auto-exclusions, .mcpbignore)
    │
    ├──► sign    (PKCS#7 over ZIP bytes, written into EOCD comment)
    │
    └──► verify  (re-hash ZIP, check signature against embedded cert chain)
```

`pack` calls `validate` internally and refuses to ship invalid manifests.

## ZIP layout

A `.mcpb` is a plain ZIP. Inside the bundle root:

- `manifest.json` (required, top level — never nested)
- `server/` or `bin/` or `src/` — server code (per server type)
- Runtime files (`node_modules/`, `server/lib/`, `pyproject.toml`, etc.)
- `.mcpbignore` — included in the ZIP only because it lives in the source dir; harmless at runtime

The host extracts the ZIP into a per-bundle directory and substitutes that path for `${__dirname}` at launch.

## Auto-exclusions in `pack`

Always excluded (cannot opt back in):

- `.git/`, `.gitignore`
- `.DS_Store`, `Thumbs.db`
- `package-lock.json`, `yarn.lock`
- `*.log`
- `.npm/`, `.yarn/`
- `.env.local`, `.env.*.local`
- `node_modules/.cache/`, `node_modules/.bin/`
- `*.map`

## `.mcpbignore`

Gitignore-syntax file at the bundle root. Use it for project-specific exclusions.

```
# Python
.venv/
__pycache__/
*.pyc
.pytest_cache/
.mypy_cache/

# Build artifacts
dist/
build/
*.tsbuildinfo

# Tests
tests/
__tests__/
*.test.js

# Docs
docs/
*.md
!README.md
```

`.mcpbignore` is additive over the auto-exclusion list — its patterns don't override the built-ins.

## File permissions

ZIP stores Unix mode bits in the external attributes field. mcpb's behavior:

- On macOS/Linux, `pack` preserves executable bits from source files.
- On Windows, ZIP doesn't carry POSIX modes. To compensate, hosts always mark the resolved `command` path executable (`mode | 0o111`) after extraction.
- `args` entries are **not** auto-chmod'd. Keep binaries as `command`, not in `args`.

## Signature format

Detached PKCS#7 (CMS), DER-encoded, SHA-256 digest. Two signature framings exist depending on bundle layout:

- The signature is appended to the ZIP file after the End-of-Central-Directory record, framed by ASCII markers `MCPB_SIG_V1` and `MCPB_SIG_END`.
- Because the underlying ZIP structure is untouched, unsigned-aware tools (Finder, `unzip`) still open the file as a ZIP.

Signed bundle byte layout:

```
[ ZIP bytes ........................... ]
[ MCPB_SIG_V1 ]
[ length-prefixed PKCS#7 DER blob       ]
[ MCPB_SIG_END ]
```

Verification re-hashes the ZIP byte range (excluding the signature footer) and validates the PKCS#7 against that digest.

## Self-signed vs. real cert

| Use case | Cert source | UX |
|----------|-------------|-----|
| Local dev | `--self-signed` flag (auto-generates) | `mcpb verify` shows a "self-signed" warning |
| Internal distribution | Internal CA-issued cert + intermediates | No warning if the CA is trusted |
| Public release | Trusted code-signing CA | No warning; some hosts may pin or whitelist publishers |

Self-signed bundles still install — the warning is informational.

## Re-signing

Calling `mcpb sign` on an already-signed bundle replaces the signature. No need to `unsign` first. The underlying ZIP bytes are unchanged, so the digest stays the same — only the PKCS#7 blob differs.

## CI integration

A representative GitHub Actions step:

```yaml
- name: Bundle MCP extension
  run: |
    npm ci --omit=dev
    npx -p @anthropic-ai/mcpb mcpb validate manifest.json
    npx -p @anthropic-ai/mcpb mcpb pack . dist/extension.mcpb
    npx -p @anthropic-ai/mcpb mcpb sign dist/extension.mcpb \
      --cert  ${{ secrets.MCPB_CERT_PATH }} \
      --key   ${{ secrets.MCPB_KEY_PATH }}
    npx -p @anthropic-ai/mcpb mcpb verify dist/extension.mcpb
```

Both `pack` and `verify` exit non-zero on failure — they're the gating steps.

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| `pack` aborts with schema errors | Manifest doesn't match `manifest_version` schema; run `mcpb validate` for line-level detail |
| Bundle installs but server fails to start | `entry_point` path wrong, or `args` missing `${__dirname}/` prefix |
| `verify` reports invalid signature on an unmodified bundle | The bundle was modified after signing (e.g., re-zipped); sign last |
| `verify` fails with "untrusted issuer" | Missing intermediate certs; pass `--intermediate` for each one |
| Server starts but can't find deps | Forgot `npm ci --omit=dev`, or Python `PYTHONPATH` not set in `env` |
| Native modules fail on user machine | Built on a different platform/arch; ship per-platform bundles or use prebuilt binaries |
| Windows users see permission denied launching binary | `command` resolves to an `args` path that wasn't chmod'd; move binary to `command` |

## Inspecting a problem bundle

```bash
mcpb info ./suspect.mcpb            # size, signature presence, cert
mcpb verify ./suspect.mcpb          # full signature + cert chain check
mcpb unpack ./suspect.mcpb ./out    # extract to inspect tree
diff -r ./out ./source/             # compare against source
```

The unpacked tree should match what was packed (minus auto-exclusions and `.mcpbignore` matches).
