# Tools Reference

## Tool Definition

Tools are defined using the `Tool` struct:

```swift
Tool(
    name: "tool_name",                    // Required: unique identifier
    title: "Human-Readable Name",         // Optional: display name
    description: "What this tool does",   // Optional: shown to clients
    inputSchema: Value,                   // Required: JSON Schema as Value
    outputSchema: Value?,                 // Optional: describe output shape
    annotations: Tool.Annotations(...)    // Optional: behavioral hints
)
```

### Input Schema

Define input parameters using JSON Schema expressed as `Value`:

```swift
Tool(
    name: "search",
    description: "Search documents",
    inputSchema: .object([
        "type": "object",
        "properties": .object([
            "query": .object([
                "type": "string",
                "description": "Search query"
            ]),
            "limit": .object([
                "type": "integer",
                "description": "Max results",
                "default": .int(10)
            ]),
            "filters": .object([
                "type": "array",
                "items": .object(["type": "string"]),
                "description": "Filter tags"
            ])
        ]),
        "required": .array(["query"])
    ])
)
```

For tools that take no arguments:

```swift
Tool(
    name: "status",
    description: "Get server status",
    inputSchema: .object(["type": "object", "properties": .object([:])])
)
```

### Annotations

Annotations hint at tool behavior without enforcing it:

```swift
Tool.Annotations(
    title: "Display Title",        // Human-readable title
    destructiveHint: false,        // May modify/delete data
    idempotentHint: true,          // Safe to retry
    openWorldHint: true,           // Interacts with external systems
    readOnlyHint: true             // Does not modify anything
)
```

Common annotation patterns:

| Tool Type | Annotations |
|-----------|------------|
| Read-only query | `readOnlyHint: true, openWorldHint: false` |
| External API call | `readOnlyHint: true, openWorldHint: true` |
| Data mutation | `destructiveHint: true, idempotentHint: false` |
| Idempotent write | `destructiveHint: false, idempotentHint: true` |

## Listing Tools

```swift
await server.withMethodHandler(ListTools.self) { params in
    // params.cursor: String? — for pagination
    .init(
        tools: [
            Tool(name: "tool1", description: "...", inputSchema: ...),
            Tool(name: "tool2", description: "...", inputSchema: ...)
        ],
        nextCursor: nil  // Set for paginated results
    )
}
```

### Pagination

For servers with many tools, paginate results:

```swift
await server.withMethodHandler(ListTools.self) { params in
    let pageSize = 50
    let offset = Int(params.cursor ?? "0") ?? 0
    let page = Array(allTools[offset..<min(offset + pageSize, allTools.count)])
    let nextCursor = offset + pageSize < allTools.count ? "\(offset + pageSize)" : nil
    return .init(tools: page, nextCursor: nextCursor)
}
```

## Handling Tool Calls

```swift
await server.withMethodHandler(CallTool.self) { params in
    // params.name: String — which tool was called
    // params.arguments: [String: Value]? — input arguments

    switch params.name {
    case "search":
        let query = params.arguments?["query"]?.stringValue ?? ""
        let limit = params.arguments?["limit"]?.intValue ?? 10
        let results = try await performSearch(query: query, limit: limit)
        return .init(content: [.text(results)], isError: false)

    case "calculate":
        guard let expr = params.arguments?["expression"]?.stringValue else {
            return .init(content: [.text("Missing 'expression' argument")], isError: true)
        }
        let result = evaluate(expr)
        return .init(content: [.text("\(result)")], isError: false)

    default:
        return .init(content: [.text("Unknown tool: \(params.name)")], isError: true)
    }
}
```

## Content Types

`CallTool.Result` contains an array of `Tool.Content` items:

### Text

```swift
.text("Plain text result")
```

### Image

```swift
.image(data: base64String, mimeType: "image/png", metadata: nil)
```

### Audio

```swift
.audio(data: base64String, mimeType: "audio/wav")
```

### Embedded Resource

```swift
.resource(resource: .text("content", uri: "resource://data", mimeType: "text/plain"))
```

### Resource Link

```swift
.resourceLink(
    uri: "file:///path/to/file",
    name: "Report",
    title: "Monthly Report",
    description: "Generated report",
    mimeType: "application/pdf"
)
```

### Multiple Content Items

Return multiple items in a single response:

```swift
return .init(content: [
    .text("Analysis complete:"),
    .image(data: chartBase64, mimeType: "image/png", metadata: nil),
    .resource(resource: .text(jsonData, uri: "result://analysis", mimeType: "application/json"))
], isError: false)
```

## Structured Content

Return machine-readable structured data alongside human-readable content:

```swift
// With raw Value
return .init(
    content: [.text("Found 42 results")],
    structuredContent: .object([
        "count": .int(42),
        "results": .array(results.map { .string($0) })
    ]),
    isError: false
)

// With Codable type
struct SearchResult: Codable { let count: Int; let items: [String] }
let result = SearchResult(count: 42, items: ["a", "b"])
return try .init(
    content: [.text("Found 42 results")],
    structuredContent: result,
    isError: false
)
```

## Error Handling in Tools

### Tool-level errors (user-facing)

Return with `isError: true` — the error message is shown to the user:

```swift
return .init(content: [.text("File not found: config.yaml")], isError: true)
```

### Protocol-level errors

Throw `MCPError` for protocol violations:

```swift
guard let name = params.arguments?["name"]?.stringValue else {
    throw MCPError.invalidParams("Missing required argument: name")
}
```

### Pattern: Validate then execute

```swift
await server.withMethodHandler(CallTool.self) { params in
    switch params.name {
    case "deploy":
        guard let env = params.arguments?["environment"]?.stringValue else {
            return .init(content: [.text("Missing 'environment' argument")], isError: true)
        }
        guard ["staging", "production"].contains(env) else {
            return .init(content: [.text("Invalid environment: \(env)")], isError: true)
        }
        do {
            let result = try await deploy(to: env)
            return .init(content: [.text("Deployed to \(env): \(result)")], isError: false)
        } catch {
            return .init(content: [.text("Deploy failed: \(error)")], isError: true)
        }
    default:
        return .init(content: [.text("Unknown tool: \(params.name)")], isError: true)
    }
}
```

## Dynamic Tool Lists

Notify clients when available tools change:

```swift
// After adding/removing tools, notify clients
try await server.notify(ToolListChangedNotification.message())
```

This requires `tools: .init(listChanged: true)` in capabilities.
