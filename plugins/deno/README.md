# claude-deno-lsp

A Claude Code plugin that provides Deno Language Server Protocol (LSP) integration for TypeScript/JavaScript code intelligence in Deno projects.

## Prerequisites

- [Deno](https://deno.land/) installed and available in PATH
- Claude Code with LSP support

Verify Deno is installed:

```bash
deno --version
```

## Installation

Add this plugin to your Claude Code configuration:

```bash
claude config add plugins /path/to/claude-deno
```

Or use `--plugin-dir` when starting Claude Code:

```bash
claude --plugin-dir /path/to/claude-deno
```

## Features

The Deno LSP provides:

- **Go to Definition** - Jump to symbol definitions
- **Hover Information** - View type information and documentation
- **Find References** - Locate all usages of a symbol
- **Document Symbols** - List all symbols in a file
- **Workspace Symbols** - Search symbols across the project
- **Diagnostics** - Real-time error and lint warnings

## Supported File Types

| Extension | Language |
|-----------|----------|
| `.ts` | TypeScript |
| `.tsx` | TypeScript React |
| `.js` | JavaScript |
| `.jsx` | JavaScript React |
| `.mts`, `.cts` | TypeScript (ESM/CJS) |
| `.mjs`, `.cjs` | JavaScript (ESM/CJS) |

## Usage

Once installed, the LSP tool becomes available for Deno files:

```
LSP goToDefinition <file> <line> <character>
LSP hover <file> <line> <character>
LSP findReferences <file> <line> <character>
LSP documentSymbol <file>
```

## Limitations

**No automatic workspace detection**: Claude Code does not currently support `rootPatterns` for conditional LSP activation. This means:

- The Deno LSP activates for **all** supported file types when the plugin is enabled
- If you have other TypeScript LSP plugins enabled, there may be conflicts
- You should enable/disable this plugin manually when switching between Deno and Node projects

**Workarounds:**

1. Only enable this plugin when working on Deno projects
2. Disable TypeScript/Node LSP plugins when using Deno projects

## Configuration

The LSP is configured with these initialization options:

| Option | Value | Description |
|--------|-------|-------------|
| `enable` | `true` | Explicitly enable Deno language features |
| `lint` | `true` | Enable Deno's built-in linter |
| `unstable` | `false` | Disable unstable APIs by default |

To customize these options, edit `.lsp.json` in the plugin directory.

## Troubleshooting

### LSP not starting

1. Verify Deno is installed: `deno --version`
2. Check that Deno is in your PATH
3. Ensure the plugin is properly loaded in Claude Code

### Conflicts with other TypeScript LSPs

If you see duplicate diagnostics or conflicting suggestions:

1. Disable other TypeScript LSP plugins
2. Use only one LSP per file type

### Unstable APIs not recognized

If you're using Deno unstable APIs, edit `.lsp.json` and set `"unstable": true`.

## Resources

- [Deno LSP Integration Docs](https://docs.deno.com/runtime/reference/lsp_integration/)
- [Deno LSP CLI Reference](https://docs.deno.com/runtime/reference/cli/lsp/)
- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference)

## License

MIT
