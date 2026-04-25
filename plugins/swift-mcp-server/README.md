# swift-mcp-server

A Claude Code plugin providing a skill for developing MCP (Model Context Protocol) servers in Swift using the official [swift-sdk](https://github.com/modelcontextprotocol/swift-sdk).

## What It Does

When loaded, this skill teaches Claude how to:

- Create MCP servers using the Swift SDK's actor-based API
- Implement tools, resources, and prompts
- Configure transports (stdio, HTTP with SSE, stateless HTTP)
- Handle errors, logging, and progress reporting
- Use advanced features like sampling, elicitation, and completions

## Installation

```bash
claude --plugin-dir /path/to/swift-mcp-server
```

Or add to your project's `.claude/settings.json`.

## Trigger Phrases

The skill activates when you mention:

- "build an MCP server in Swift"
- "create a Swift MCP server"
- "use swift-sdk"
- "implement MCP tools in Swift"
- "Swift MCP"

## Contents

```
skills/swift-mcp-server/
├── SKILL.md                          # Core patterns and quick reference
├── references/
│   ├── server-setup.md               # Server creation, capabilities, lifecycle
│   ├── tools.md                      # Tool definition, annotations, structured content
│   ├── resources.md                  # Resources, templates, subscriptions
│   ├── prompts.md                    # Prompt templates and messages
│   ├── transports.md                 # All transport types
│   ├── error-handling.md             # MCPError catalog
│   ├── advanced.md                   # Logging, progress, sampling, elicitation
│   └── value-type.md                 # The Value enum and JSON schema construction
└── examples/
    ├── minimal-server.swift          # Bare minimum server
    ├── tool-server.swift             # Tools with progress and logging
    ├── resource-server.swift         # Resources, templates, subscriptions
    └── http-server.swift             # HTTP transport with validation
```
