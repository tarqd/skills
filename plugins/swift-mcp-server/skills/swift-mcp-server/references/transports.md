# Transports Reference

## Transport Protocol

All transports conform to the `Transport` actor protocol:

```swift
public protocol Transport: Actor {
    var logger: Logger { get }
    func connect() async throws
    func disconnect() async
    func send(_ data: Data) async throws
    func receive() -> AsyncThrowingStream<Data, Swift.Error>
}
```

## StdioTransport

The most common transport for MCP servers. Communicates over stdin/stdout using JSON-RPC.

```swift
import MCP

// Default (stdin/stdout)
let transport = StdioTransport()

// With custom logger
import Logging
let logger = Logger(label: "my-server")
let transport = StdioTransport(logger: logger)

// With explicit file descriptors
let transport = StdioTransport(
    input: .standardInput,
    output: .standardOutput,
    logger: logger
)
```

**Use for**: CLI tools, subprocess-based servers, `claude_desktop_config.json` integration.

**Important**: Do not write to stdout for anything except MCP messages — use stderr for debug logging:

```swift
var logger = Logger(label: "my-server", factory: { StreamLogHandler.standardError(label: $0) })
logger.logLevel = .debug
```

### Full stdio server example

```swift
import MCP
import Logging

@main
struct MyServer {
    static func main() async throws {
        var logger = Logger(label: "my-server",
                            factory: { StreamLogHandler.standardError(label: $0) })
        logger.logLevel = .info

        let server = Server(
            name: "my-server", version: "1.0.0",
            capabilities: .init(tools: .init())
        )
        // ... register handlers ...

        let transport = StdioTransport(logger: logger)
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }
}
```

## StatefulHTTPServerTransport

Full HTTP server transport with SSE (Server-Sent Events) streaming and session management. Suitable for long-running connections where the server pushes updates to clients.

```swift
import MCP
import Logging

let transport = StatefulHTTPServerTransport(
    sessionIDGenerator: UUIDSessionIDGenerator(),  // Generate unique session IDs
    retryInterval: 5000,                           // SSE retry interval in ms
    logger: logger
)

try await server.start(transport: transport)
```

### Handling HTTP Requests

The transport does not include its own HTTP server — integrate with your HTTP framework (e.g., SwiftNIO, Vapor, Hummingbird):

```swift
// In your HTTP request handler:
let response = await transport.handleRequest(httpRequest)
// Return response to client
```

### HTTPApp (Built-in NIO Server)

The SDK includes an `HTTPApp` that wraps SwiftNIO for convenience:

```swift
import MCP

let app = HTTPApp(
    configuration: .init(
        host: "127.0.0.1",
        port: 3001,
        endpoint: "/mcp"
    ),
    validationPipeline: StandardValidationPipeline(validators: [
        OriginValidator.localhost(port: 3001),
        AcceptHeaderValidator(mode: .sseRequired),
        ContentTypeValidator(),
        ProtocolVersionValidator(),
        SessionValidator()
    ]),
    serverFactory: { sessionID in
        // Create a new server instance per session
        await createServer()
    },
    logger: logger
)

try await app.start()
```

### Validation Pipeline

HTTP servers should validate incoming requests. Built-in validators:

| Validator | Purpose |
|-----------|---------|
| `OriginValidator` | Check request origin (CORS) |
| `AcceptHeaderValidator` | Verify Accept header for SSE |
| `ContentTypeValidator` | Verify Content-Type header |
| `ProtocolVersionValidator` | Check MCP protocol version |
| `SessionValidator` | Validate session IDs |

Custom validators implement `HTTPRequestValidator`:

```swift
struct APIKeyValidator: HTTPRequestValidator {
    func validate(_ request: HTTPRequest) async throws -> HTTPValidationResult {
        guard request.headers["X-API-Key"] == expectedKey else {
            return .reject(status: 401, body: "Unauthorized")
        }
        return .accept
    }
}
```

## StatelessHTTPServerTransport

Simple HTTP request-response transport without SSE streaming. Each request gets a complete response.

```swift
let transport = StatelessHTTPServerTransport(logger: logger)
try await server.start(transport: transport)

// In HTTP handler:
let response = await transport.handleRequest(httpRequest)
```

**Use for**: Serverless functions, simple HTTP APIs, environments where SSE is not supported.

**Limitations**: No server-initiated notifications (no SSE), no progress updates during tool calls.

## InMemoryTransport

For testing — creates a connected pair of transports in the same process:

```swift
let (clientTransport, serverTransport) = await InMemoryTransport.createConnectedPair()

// Start server
try await server.start(transport: serverTransport)

// Connect client
try await client.connect(transport: clientTransport)

// Now client and server can communicate
let tools = try await client.listTools()
```

### Testing Pattern

```swift
import Testing
import MCP

@Test func testMyServer() async throws {
    let server = createMyServer()
    let (clientTransport, serverTransport) = await InMemoryTransport.createConnectedPair()

    try await server.start(transport: serverTransport)

    let client = Client(name: "test-client", version: "1.0.0")
    try await client.connect(transport: clientTransport)

    // Test tools
    let tools = try await client.listTools()
    #expect(tools.tools.contains { $0.name == "my_tool" })

    // Test tool call
    let result = try await client.callTool(name: "my_tool", arguments: ["key": "value"])
    #expect(result.isError != true)

    await server.stop()
}
```

## NetworkTransport

TCP/UDP transport using Apple's Network.framework. **Apple platforms only**.

```swift
import Network

let transport = NetworkTransport(
    connection: NWConnection(host: "localhost", port: 8080, using: .tcp),
    logger: logger
)
```

**Use for**: Direct TCP communication on Apple platforms.

## Custom Transport

Implement `Transport` for custom communication channels:

```swift
public actor MyCustomTransport: Transport {
    public nonisolated let logger: Logger
    private var isConnected = false
    private let messageStream: AsyncThrowingStream<Data, any Swift.Error>
    private let messageContinuation: AsyncThrowingStream<Data, any Swift.Error>.Continuation

    public init(logger: Logger? = nil) {
        self.logger = logger ?? Logger(label: "custom-transport")
        var continuation: AsyncThrowingStream<Data, any Swift.Error>.Continuation!
        self.messageStream = AsyncThrowingStream { continuation = $0 }
        self.messageContinuation = continuation
    }

    public func connect() async throws {
        isConnected = true
    }

    public func disconnect() async {
        isConnected = false
        messageContinuation.finish()
    }

    public func send(_ data: Data) async throws {
        guard isConnected else {
            throw MCPError.connectionClosed
        }
        // Send data over your custom channel
    }

    public func receive() -> AsyncThrowingStream<Data, any Swift.Error> {
        messageStream
    }

    // Call this when data arrives from your custom channel
    public func didReceive(_ data: Data) {
        messageContinuation.yield(data)
    }
}
```

## Transport Selection Guide

| Scenario | Transport | Why |
|----------|-----------|-----|
| CLI tool / subprocess | `StdioTransport` | Standard, works everywhere |
| Web API with streaming | `StatefulHTTPServerTransport` | SSE for real-time updates |
| Serverless / Lambda | `StatelessHTTPServerTransport` | No persistent connections |
| Unit tests | `InMemoryTransport` | Fast, no I/O |
| Apple TCP/UDP | `NetworkTransport` | Native Network.framework |
| Custom protocol | Implement `Transport` | Full control |
