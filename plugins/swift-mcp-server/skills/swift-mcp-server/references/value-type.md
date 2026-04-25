# Value Type Reference

## Overview

`Value` is a dynamic JSON type used throughout the MCP SDK for schemas, arguments, metadata, and structured content:

```swift
public enum Value: Hashable, Sendable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case data(mimeType: String?, Data)
    case array([Value])
    case object([String: Value])
}
```

## Creating Values

### Direct Construction

```swift
let null: Value = .null
let flag: Value = .bool(true)
let count: Value = .int(42)
let score: Value = .double(98.6)
let name: Value = .string("hello")
let list: Value = .array([.int(1), .int(2), .int(3)])
let dict: Value = .object(["key": .string("value")])
```

### Literal Syntax

`Value` conforms to all `ExpressibleBy*Literal` protocols:

```swift
let schema: Value = .object([
    "type": "object",                          // StringLiteral → .string
    "properties": .object([
        "name": .object(["type": "string"]),   // Nested literals
        "age": .object(["type": "integer"])
    ]),
    "required": .array(["name"])               // ArrayLiteral with StringLiterals
])
```

Supported literal conversions:
- `"text"` → `.string("text")`
- `42` → `.int(42)`
- `3.14` → `.double(3.14)`
- `true` / `false` → `.bool(true)` / `.bool(false)`
- `nil` → `.null`
- `[...]` → `.array([...])`
- `[key: value]` → `.object([key: value])`

### From Codable

Encode any `Codable` type into a `Value`:

```swift
struct Config: Codable {
    let host: String
    let port: Int
    let debug: Bool
}

let config = Config(host: "localhost", port: 8080, debug: true)
let value = try Value(config)
// .object(["host": .string("localhost"), "port": .int(8080), "debug": .bool(true)])
```

## Accessing Values

### Type-Specific Accessors

```swift
let value: Value = .string("hello")

value.stringValue   // Optional<String> → "hello"
value.intValue      // Optional<Int> → nil
value.doubleValue   // Optional<Double> → nil
value.boolValue     // Optional<Bool> → nil
value.arrayValue    // Optional<[Value]> → nil
value.objectValue   // Optional<[String: Value]> → nil
value.isNull        // Bool → false
```

### Nested Access

```swift
let data: Value = .object([
    "user": .object([
        "name": .string("Alice"),
        "scores": .array([.int(95), .int(87), .int(92)])
    ])
])

// Chain optional access
let name = data.objectValue?["user"]?.objectValue?["name"]?.stringValue  // "Alice"
let firstScore = data.objectValue?["user"]?.objectValue?["scores"]?.arrayValue?.first?.intValue  // 95
```

### Extracting Tool Arguments

Common pattern in `CallTool` handlers:

```swift
await server.withMethodHandler(CallTool.self) { params in
    switch params.name {
    case "create_user":
        let name = params.arguments?["name"]?.stringValue ?? "Unknown"
        let age = params.arguments?["age"]?.intValue ?? 0
        let tags = params.arguments?["tags"]?.arrayValue?.compactMap(\.stringValue) ?? []
        let isAdmin = params.arguments?["admin"]?.boolValue ?? false

        // ...
    }
}
```

## Building JSON Schemas

### Simple Object Schema

```swift
let schema: Value = .object([
    "type": "object",
    "properties": .object([
        "query": .object([
            "type": "string",
            "description": "Search query"
        ])
    ]),
    "required": .array(["query"])
])
```

### Complex Schema with Nested Types

```swift
let schema: Value = .object([
    "type": "object",
    "properties": .object([
        "name": .object(["type": "string", "description": "User name"]),
        "age": .object(["type": "integer", "minimum": .int(0)]),
        "email": .object(["type": "string", "format": "email"]),
        "role": .object([
            "type": "string",
            "enum": .array(["admin", "user", "guest"]),
            "default": "user"
        ]),
        "address": .object([
            "type": "object",
            "properties": .object([
                "street": .object(["type": "string"]),
                "city": .object(["type": "string"]),
                "zip": .object(["type": "string"])
            ]),
            "required": .array(["street", "city"])
        ]),
        "tags": .object([
            "type": "array",
            "items": .object(["type": "string"]),
            "maxItems": .int(10)
        ])
    ]),
    "required": .array(["name", "email"])
])
```

### Empty Object (No Arguments)

```swift
let schema: Value = .object(["type": "object", "properties": .object([:])])
```

### Schema with $ref and $defs

```swift
let schema: Value = .object([
    "$schema": .string("https://json-schema.org/draft/2020-12/schema"),
    "type": .string("object"),
    "$defs": .object([
        "address": .object([
            "type": .string("object"),
            "properties": .object([
                "street": .object(["type": .string("string")]),
                "city": .object(["type": .string("string")])
            ])
        ])
    ]),
    "properties": .object([
        "home": .object(["$ref": .string("#/$defs/address")]),
        "work": .object(["$ref": .string("#/$defs/address")])
    ])
])
```

## Value in Structured Content

Use `Value` to return machine-readable structured data from tools:

```swift
// Raw Value
return .init(
    content: [.text("Found 3 users")],
    structuredContent: .object([
        "count": .int(3),
        "users": .array([
            .object(["name": "Alice", "role": "admin"]),
            .object(["name": "Bob", "role": "user"]),
            .object(["name": "Carol", "role": "user"])
        ])
    ]),
    isError: false
)

// From Codable
struct Result: Codable { let count: Int; let users: [User] }
return try .init(
    content: [.text("Found \(result.count) users")],
    structuredContent: result,
    isError: false
)
```

## Codable Conformance

`Value` is fully `Codable`, serializing to standard JSON:

```swift
let value: Value = .object(["name": "test", "count": .int(42)])
let data = try JSONEncoder().encode(value)
// {"name":"test","count":42}

let decoded = try JSONDecoder().decode(Value.self, from: data)
```

## Equality and Hashing

`Value` conforms to `Hashable` and `Equatable`:

```swift
let a: Value = .object(["key": "value"])
let b: Value = .object(["key": "value"])
a == b  // true

var set = Set<Value>()
set.insert(.string("hello"))
```
