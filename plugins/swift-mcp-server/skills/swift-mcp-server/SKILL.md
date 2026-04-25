---
name: swift-mcp-server
user_invokable: true
description: >-
  This skill should be used when the user asks to "build an MCP server in Swift",
  "create a Swift MCP server", "use swift-sdk", "implement MCP tools in Swift",
  "add MCP resources in Swift", "add MCP prompts in Swift", "Swift MCP",
  "MCP server Swift", "Swift MCP HTTP server", "test MCP server Swift",
  "implement Model Context Protocol in Swift", or mentions building servers
  with the modelcontextprotocol/swift-sdk package.
---

# Swift MCP Server Development

Build MCP (Model Context Protocol) servers in Swift using the official `swift-sdk` package (`github.com/modelcontextprotocol/swift-sdk`). The SDK provides a type-safe, actor-based API for creating servers that expose tools, resources, and prompts to MCP clients.

## Installation

Add the SDK as a Swift package dependency:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.11.0")
]
// In target dependencies:
.product(name: "MCP", package: "swift-sdk")
```

**Requirements**: Swift 6.0+, macOS 13.0+ / iOS 16.0+ / Linux

## Core Concepts

### The Server Actor

`Server` is a Swift `actor` — all interactions require `await`. Create one with a name, version, and declared capabilities:

```swift
import MCP

let server = Server(
    name: "my-server",
    version: "1.0.0",
    capabilities: .init(
        tools: .init(listChanged: true),
        resources: .init(subscribe: true, listChanged: true),
        prompts: .init(listChanged: true),
        logging: .init()
    )
)
```

Only declare capabilities the server actually implements. Set `listChanged: true` if the server will notify clients when lists change dynamically.

### Handler Registration Pattern

Register handlers for MCP methods using `withMethodHandler`. Each handler receives typed parameters and returns a typed result:

```swift
await server.withMethodHandler(ListTools.self) { params in
    .init(tools: [ /* tool definitions */ ])
}

await server.withMethodHandler(CallTool.self) { params in
    switch params.name {
    case "my-tool":
        return .init(content: [.text("result")], isError: false)
    default:
        return .init(content: [.text("Unknown tool: \(params.name)")], isError: true)
    }
}
```

When referencing the server from within its own handlers (e.g., to send notifications), capture it with `[weak server]`:

```swift
await server.withMethodHandler(CallTool.self) { [weak server] params in
    try await server?.log(level: .info, logger: "tool", data: .string("Called \(params.name)"))
    return .init(content: [.text("done")], isError: false)
}
```

### Transports

Start the server with a transport. The most common for CLI-based servers:

```swift
let transport = StdioTransport()
try await server.start(transport: transport)
await server.waitUntilCompleted()
```

Available transports:

| Transport | Use Case |
|-----------|----------|
| `StdioTransport` | CLI tools, subprocess communication (most common) |
| `StatefulHTTPServerTransport` | HTTP server with SSE streaming and sessions |
| `StatelessHTTPServerTransport` | Simple HTTP request-response |
| `InMemoryTransport` | Testing (create connected pairs) |

See **`references/transports.md`** for detailed transport configuration.

### The Value Type

`Value` is the dynamic JSON type used throughout the SDK for schemas, arguments, and data. It conforms to all `ExpressibleBy*Literal` protocols:

```swift
let schema: Value = .object([
    "type": "object",
    "properties": .object([
        "name": .object(["type": "string", "description": "User name"]),
        "count": .object(["type": "integer"])
    ]),
    "required": .array(["name"])
])
```

Access values with: `.stringValue`, `.intValue`, `.doubleValue`, `.boolValue`, `.arrayValue`, `.objectValue`. Construct from any `Codable` with `try Value(myStruct)`.

See **`references/value-type.md`** for complete reference.

## Implementing Tools

Define tools in `ListTools` and handle calls in `CallTool`:

```swift
await server.withMethodHandler(ListTools.self) { _ in
    .init(tools: [
        Tool(
            name: "get_weather",
            description: "Get current weather for a city",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "city": .object(["type": "string", "description": "City name"])
                ]),
                "required": .array(["city"])
            ]),
            annotations: .init(readOnlyHint: true, openWorldHint: true)
        )
    ])
}

await server.withMethodHandler(CallTool.self) { params in
    switch params.name {
    case "get_weather":
        let city = params.arguments?["city"]?.stringValue ?? "Unknown"
        let weather = try await fetchWeather(for: city)
        return .init(content: [.text(weather)], isError: false)
    default:
        return .init(content: [.text("Unknown tool: \(params.name)")], isError: true)
    }
}
```

Return errors with `isError: true` for tool-level failures. Throw `MCPError` for protocol-level errors.

See **`references/tools.md`** for annotations, structured content, and advanced patterns.

## Implementing Resources

Expose data via `ListResources` and `ReadResource`:

```swift
await server.withMethodHandler(ListResources.self) { _ in
    .init(resources: [
        Resource(name: "Config", uri: "config://app", description: "App config", mimeType: "application/json")
    ])
}

await server.withMethodHandler(ReadResource.self) { params in
    switch params.uri {
    case "config://app":
        return .init(contents: [.text("{\"debug\": true}", uri: params.uri, mimeType: "application/json")])
    default:
        throw MCPError.invalidParams("Unknown resource: \(params.uri)")
    }
}
```

See **`references/resources.md`** for templates, subscriptions, and binary resources.

## Implementing Prompts

Expose prompt templates via `ListPrompts` and `GetPrompt`:

```swift
await server.withMethodHandler(ListPrompts.self) { _ in
    .init(prompts: [
        Prompt(name: "review-code", description: "Review code for issues",
               arguments: [.init(name: "language", description: "Language", required: true)])
    ])
}

await server.withMethodHandler(GetPrompt.self) { params in
    let lang = params.arguments?["language"]?.stringValue ?? "unknown"
    return .init(
        description: "Code review for \(lang)",
        messages: [.user(.text(text: "Review this \(lang) code for issues."))]
    )
}
```

See **`references/prompts.md`** for multi-message prompts and embedded resources.

## Error Handling

`MCPError` provides standard JSON-RPC error codes:

```swift
throw MCPError.invalidParams("Missing required argument: name")
throw MCPError.invalidRequest("Unsupported operation")
throw MCPError.internalError("Database connection failed")
```

Errors thrown from handlers are automatically converted to JSON-RPC error responses. Non-`MCPError` errors are wrapped as `internalError`.

See **`references/error-handling.md`** for the full error catalog.

## Advanced Features

For logging, progress notifications, sampling, elicitation, roots, and completions, see **`references/advanced.md`**.

## Complete Server Pattern

```swift
import MCP

@main
struct MyMCPServer {
    static func main() async throws {
        let server = Server(
            name: "my-server", version: "1.0.0",
            capabilities: .init(tools: .init(listChanged: true))
        )

        await server.withMethodHandler(ListTools.self) { _ in
            .init(tools: [ /* ... */ ])
        }
        await server.withMethodHandler(CallTool.self) { params in
            // handle tool calls
        }

        let transport = StdioTransport()
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }
}
```

## Additional Resources

### Reference Files

For detailed patterns and API reference, consult:
- **`references/server-setup.md`** — Server creation, capabilities, lifecycle, configuration
- **`references/tools.md`** — Tool definition, annotations, structured content
- **`references/resources.md`** — Resources, templates, subscriptions, binary content
- **`references/prompts.md`** — Prompt templates, arguments, messages
- **`references/transports.md`** — All transports: stdio, HTTP stateful/stateless, in-memory, custom
- **`references/error-handling.md`** — MCPError catalog and error patterns
- **`references/advanced.md`** — Logging, progress, sampling, elicitation, roots, completions
- **`references/value-type.md`** — The Value enum, JSON schema construction, accessors

### Example Files

Working server examples in `examples/`:
- **`examples/minimal-server.swift`** — Bare minimum MCP server
- **`examples/tool-server.swift`** — Server focused on tool implementation
- **`examples/resource-server.swift`** — Server with resources, templates, and subscriptions
- **`examples/http-server.swift`** — HTTP transport server with validation
