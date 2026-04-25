# Error Handling Reference

## MCPError

`MCPError` is the primary error type, mapping to JSON-RPC 2.0 error codes:

```swift
public enum MCPError: Error, Sendable, Codable, Equatable, Hashable {
    // Standard JSON-RPC 2.0 errors
    case parseError(String?)           // -32700: Invalid JSON
    case invalidRequest(String?)       // -32600: Not a valid request
    case methodNotFound(String?)       // -32601: Method does not exist
    case invalidParams(String?)        // -32602: Invalid method parameters
    case internalError(String?)        // -32603: Internal error

    // Server errors (-32000 to -32099)
    case serverError(code: Int, message: String)

    // Transport
    case connectionClosed              // Connection lost
    case transportError(Error)         // Underlying transport error
}
```

## Using MCPError in Handlers

### Parameter Validation

```swift
await server.withMethodHandler(CallTool.self) { params in
    guard let name = params.arguments?["name"]?.stringValue else {
        throw MCPError.invalidParams("Missing required argument: name")
    }
    guard name.count <= 100 else {
        throw MCPError.invalidParams("name must be 100 characters or fewer")
    }
    // ...
}
```

### Unknown Methods/Resources

```swift
// Unknown tool
return .init(content: [.text("Unknown tool: \(params.name)")], isError: true)

// Unknown resource
throw MCPError.invalidParams("Unknown resource: \(params.uri)")

// Unknown prompt
throw MCPError.invalidRequest("Unknown prompt: \(params.name)")
```

### Internal Errors

```swift
do {
    let data = try await fetchFromDatabase()
    return .init(content: [.text(data)], isError: false)
} catch {
    throw MCPError.internalError("Database error: \(error.localizedDescription)")
}
```

### Custom Server Errors

```swift
throw MCPError.serverError(code: -32001, message: "Rate limit exceeded")
throw MCPError.serverError(code: -32050, message: "Service unavailable")
```

Server error codes must be in the range -32000 to -32099.

## Error Propagation

Errors thrown from `withMethodHandler` closures are automatically handled:

1. **`MCPError`** — serialized directly as the JSON-RPC error response
2. **Any other `Swift.Error`** — wrapped in `MCPError.internalError(error.localizedDescription)`

This means any unhandled error becomes a generic internal error. Throw `MCPError` explicitly for meaningful error messages.

## Tool Errors vs Protocol Errors

**Tool-level errors** (reported to user, execution "succeeded" from protocol perspective):

```swift
return .init(content: [.text("File not found: config.yaml")], isError: true)
```

**Protocol-level errors** (request failed at protocol level):

```swift
throw MCPError.invalidParams("Missing argument")
```

Use tool-level errors for expected failure cases (file not found, invalid input). Use protocol errors for violations of the protocol contract (missing required params, unknown method).

## Error Patterns

### Guard-based Validation

```swift
await server.withMethodHandler(CallTool.self) { params in
    switch params.name {
    case "process":
        guard let input = params.arguments?["input"]?.stringValue else {
            return .init(content: [.text("Missing 'input' argument")], isError: true)
        }
        guard input.count > 0 else {
            return .init(content: [.text("'input' must not be empty")], isError: true)
        }
        // process...
    default:
        return .init(content: [.text("Unknown tool: \(params.name)")], isError: true)
    }
}
```

### Try-Catch in Handlers

```swift
await server.withMethodHandler(CallTool.self) { params in
    switch params.name {
    case "fetch":
        do {
            let result = try await externalAPI.fetch(params.arguments)
            return .init(content: [.text(result)], isError: false)
        } catch let error as APIError {
            return .init(content: [.text("API error: \(error.message)")], isError: true)
        } catch {
            return .init(content: [.text("Unexpected error: \(error)")], isError: true)
        }
    default:
        return .init(content: [.text("Unknown tool")], isError: true)
    }
}
```

### Connection Error Handling

```swift
do {
    try await server.start(transport: transport)
} catch MCPError.connectionClosed {
    print("Connection closed unexpectedly")
} catch MCPError.transportError(let underlying) {
    print("Transport error: \(underlying)")
} catch {
    print("Failed to start: \(error)")
}
```
