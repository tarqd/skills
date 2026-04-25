# Server Setup Reference

## Creating a Server

The `Server` actor is the central type. Initialize with metadata and capabilities:

```swift
import MCP

let server = Server(
    name: "my-server",           // Required: unique server identifier
    version: "1.0.0",            // Required: semantic version
    title: "My MCP Server",      // Optional: human-readable display name
    instructions: "This server provides weather data tools",  // Optional: usage instructions for clients
    capabilities: Server.Capabilities(
        completions: .init(),                                  // Autocomplete suggestions
        logging: .init(),                                      // Structured log messages
        prompts: .init(listChanged: true),                     // Prompt templates
        resources: .init(subscribe: true, listChanged: true),  // Data resources
        tools: .init(listChanged: true)                        // Callable tools
    ),
    configuration: .default       // .default or .strict
)
```

### Capabilities

Only declare capabilities the server actually implements. Each capability enables the corresponding MCP methods:

| Capability | Enables Methods | Options |
|-----------|----------------|---------|
| `tools` | `tools/list`, `tools/call` | `listChanged: Bool?` — notify on list changes |
| `resources` | `resources/list`, `resources/read`, `resources/templates/list` | `subscribe: Bool?`, `listChanged: Bool?` |
| `prompts` | `prompts/list`, `prompts/get` | `listChanged: Bool?` |
| `logging` | `logging/setLevel` + server can send log notifications | (none) |
| `completions` | `completion/complete` | (none) |
| `sampling` | Server can request `sampling/createMessage` from client | (none) |

### Configuration

```swift
// Default: lenient mode, allows requests before initialization completes
Server.Configuration.default  // Configuration(strict: false)

// Strict: enforces MCP protocol — no requests until initialization handshake completes
Server.Configuration.strict   // Configuration(strict: true)
```

Use `.strict` for production servers that must comply with the MCP spec exactly.

## Starting the Server

### Basic Start

```swift
let transport = StdioTransport()
try await server.start(transport: transport)
await server.waitUntilCompleted()
```

### Start with Initialize Hook

Inspect client info and optionally reject connections:

```swift
try await server.start(transport: transport) { clientInfo, clientCapabilities in
    print("Client: \(clientInfo.name) v\(clientInfo.version)")

    // Reject specific clients
    guard clientInfo.name != "blocked-client" else {
        throw MCPError.invalidRequest("Client not allowed")
    }

    // Check client capabilities
    if clientCapabilities.sampling != nil {
        print("Client supports sampling")
    }
}
```

### Graceful Shutdown

```swift
await server.stop()
```

## Production Server Pattern

Use Swift Service Lifecycle for production deployments:

```swift
import ServiceLifecycle
import MCP

struct MCPService: Service {
    let server: Server
    let transport: Transport

    func run() async throws {
        try await server.start(transport: transport)
        try await gracefulShutdown()
    }
}

@main
struct App {
    static func main() async throws {
        let server = Server(name: "prod-server", version: "1.0.0",
                            capabilities: .init(tools: .init()))
        // ... register handlers ...

        let transport = StdioTransport()
        let service = MCPService(server: server, transport: transport)
        let group = ServiceGroup(services: [service])
        try await group.run()
    }
}
```

## Handler Registration

### Method Handlers

Register handlers using `withMethodHandler`. Returns `Self` for optional chaining:

```swift
await server.withMethodHandler(ListTools.self) { params in
    // params: ListTools.Parameters
    // return: ListTools.Result
    return .init(tools: [...])
}
```

The handler closure is `@escaping @Sendable` — capture only sendable values. Use `[weak server]` when referencing the server itself.

### Notification Handlers

Listen for client notifications:

```swift
await server.onNotification(RootsListChangedNotification.self) { message in
    // React to notification
}
```

### Sending Notifications

```swift
try await server.notify(ToolListChangedNotification.message())
try await server.notify(ResourceListChangedNotification.message())
try await server.notify(ResourceUpdatedNotification.message(.init(uri: "config://app")))
try await server.notify(PromptListChangedNotification.message())
```

## Server Info

Access server metadata:

```swift
let info = await server.serverInfo
// info.name, info.version, info.title
```

## Cancellation

Cancel a pending request:

```swift
await server.cancelRequest(requestID, reason: "Timeout")
```
