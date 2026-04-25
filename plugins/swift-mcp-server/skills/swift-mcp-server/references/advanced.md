# Advanced Features Reference

## Logging

Send structured log messages from server to client. Requires `logging: .init()` in capabilities.

### Sending Logs

```swift
// String log
try await server.log(level: .info, logger: "db", data: .string("Connected to database"))

// Structured log
try await server.log(level: .error, logger: "api", data: .object([
    "message": .string("Request failed"),
    "endpoint": .string("/users"),
    "status": .int(500)
]))

// Codable type
struct LogEntry: Codable { let event: String; let duration: Double }
try await server.log(level: .info, logger: "perf",
                     data: LogEntry(event: "query", duration: 0.42))
```

### Log Levels

```swift
public enum LogLevel: String {
    case debug, info, notice, warning, error, critical, alert, emergency
}
```

### Handling SetLoggingLevel

Clients can request a minimum log level:

```swift
actor LogState {
    var minLevel: LogLevel = .info
    func setLevel(_ level: LogLevel) { minLevel = level }
}

let logState = LogState()

await server.withMethodHandler(SetLoggingLevel.self) { params in
    await logState.setLevel(params.level)
    return Empty()
}
```

### Logging During Tool Execution

```swift
await server.withMethodHandler(CallTool.self) { [weak server] params in
    try await server?.log(level: .info, logger: "tool",
                          data: .string("Executing \(params.name)"))
    // ... do work ...
    try await server?.log(level: .info, logger: "tool",
                          data: .string("Completed \(params.name)"))
    return .init(content: [.text("Done")], isError: false)
}
```

## Progress Notifications

Report progress during long-running operations. The client sends a `progressToken` in the request metadata.

```swift
await server.withMethodHandler(CallTool.self) { [weak server] params in
    let total = 100

    if let token = params._meta?.progressToken {
        for i in stride(from: 0, through: total, by: 25) {
            try await server?.notify(ProgressNotification.message(
                .init(progressToken: token, progress: Double(i), total: Double(total),
                      message: "Processing \(i)%")
            ))
            try await Task.sleep(for: .milliseconds(100))
        }
    }

    return .init(content: [.text("Processing complete")], isError: false)
}
```

`ProgressNotification` fields:
- `progressToken` — token from the request's `_meta`
- `progress` — current progress value
- `total` — optional total for percentage calculation
- `message` — optional status message

## Completions (Autocomplete)

Provide autocomplete suggestions for prompt arguments and resource template parameters. Requires `completions: .init()` in capabilities.

```swift
await server.withMethodHandler(Complete.self) { params in
    let argName = params.argument.name
    let currentValue = params.argument.value

    switch params.ref {
    case .prompt(let ref):
        if ref.name == "review-code" && argName == "language" {
            let languages = ["swift", "python", "rust", "go", "typescript"]
            let matches = languages.filter { $0.hasPrefix(currentValue.lowercased()) }
            return .init(completion: .init(values: matches, total: matches.count, hasMore: false))
        }

    case .resource(let ref):
        if argName == "path" {
            let paths = try await listFiles(prefix: currentValue)
            return .init(completion: .init(values: paths, total: paths.count,
                                           hasMore: paths.count > 100))
        }
    }

    return .init(completion: .init(values: []))
}
```

## Sampling (Request LLM from Client)

Ask the connected client to perform an LLM completion. The client must support sampling.

```swift
let result = try await server.requestSampling(
    messages: [.user(.text("Analyze this data: \(data)"))],
    systemPrompt: "You are a data analyst. Be concise.",
    temperature: 0.7,
    maxTokens: 500
)

// result.content — the LLM response
// result.model — which model was used
// result.stopReason — why generation stopped
```

### Multi-turn Sampling

```swift
let result = try await server.requestSampling(
    messages: [
        .user(.text("What is 2+2?")),
        .assistant(.text("4")),
        .user(.text("Now multiply by 10"))
    ],
    maxTokens: 100
)
```

### Extracting Text from Sampling Result

```swift
let responseText = result.content.asArray
    .compactMap { block -> String? in
        if case .text(let text) = block { return text }
        return nil
    }
    .joined(separator: "\n")
```

## Elicitation (Request User Input from Client)

Ask the client to collect structured input from the user:

```swift
let result = try await server.requestElicitation(
    message: "Please provide your database credentials",
    requestedSchema: Elicitation.RequestSchema(
        properties: [
            "host": .object([
                "type": .string("string"),
                "description": .string("Database host")
            ]),
            "port": .object([
                "type": .string("integer"),
                "default": .int(5432)
            ]),
            "username": .object([
                "type": .string("string")
            ]),
            "password": .object([
                "type": .string("string")
            ])
        ],
        required: ["host", "username", "password"]
    )
)
```

### Handling Elicitation Results

```swift
switch result.action {
case .accept:
    let host = result.content?["host"]?.stringValue ?? "localhost"
    let port = result.content?["port"]?.intValue ?? 5432
    let username = result.content?["username"]?.stringValue ?? ""
    // Use the values...

case .decline:
    return .init(content: [.text("User declined to provide credentials")], isError: true)

case .cancel:
    return .init(content: [.text("User cancelled")], isError: true)
}
```

### Elicitation Schema Types

Supported property types in the schema:
- `"string"` — text input
- `"integer"` — whole number
- `"number"` — decimal number
- `"boolean"` — true/false toggle
- `"string"` with `"enum"` — dropdown select
- `"array"` with `"items"` containing `"enum"` — multi-select

### Enum Selections

```swift
// Simple dropdown
"priority": .object([
    "type": .string("string"),
    "enum": .array([.string("low"), .string("medium"), .string("high")])
])

// Titled dropdown (display names)
"status": .object([
    "type": .string("string"),
    "oneOf": .array([
        .object(["const": .string("active"), "title": .string("Active")]),
        .object(["const": .string("inactive"), "title": .string("Inactive")])
    ])
])
```

## Roots (Filesystem Boundaries from Client)

Request the list of filesystem roots the client has access to:

```swift
let roots = try await server.listRoots()
for root in roots {
    print("Root: \(root.uri)")  // e.g., "file:///Users/user/project"
    print("Name: \(root.name ?? "unnamed")")
}
```

### React to Root Changes

```swift
await server.onNotification(RootsListChangedNotification.self) { [weak server] _ in
    let updatedRoots = try await server?.listRoots()
    // Update internal state based on new roots
}
```

## Ping

The SDK handles ping/pong automatically. To manually ping the client:

```swift
try await server.ping()
```

## Request Context and Metadata

Handlers can access request metadata via `params._meta`:

```swift
await server.withMethodHandler(CallTool.self) { params in
    // Progress token for reporting progress
    let progressToken = params._meta?.progressToken

    // Custom metadata from client
    let customField = params._meta?["myField"]

    // ...
}
```
