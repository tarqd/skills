# Resources Reference

## Resource Definition

Resources expose data to clients using URI-based addressing:

```swift
Resource(
    name: "Config",                   // Required: display name
    uri: "config://app",              // Required: unique URI
    title: "Application Config",      // Optional: human-readable title
    description: "App configuration", // Optional: description
    mimeType: "application/json"      // Optional: content type
)
```

## Listing Resources

```swift
await server.withMethodHandler(ListResources.self) { params in
    // params.cursor: String? — for pagination
    .init(resources: [
        Resource(name: "App Config", uri: "config://app",
                 description: "Application configuration", mimeType: "application/json"),
        Resource(name: "User Data", uri: "data://users",
                 description: "User database", mimeType: "application/json"),
        Resource(name: "Logo", uri: "asset://logo.png",
                 description: "Company logo", mimeType: "image/png")
    ])
}
```

## Reading Resources

### Text Content

```swift
await server.withMethodHandler(ReadResource.self) { params in
    switch params.uri {
    case "config://app":
        let config = try await loadConfig()
        return .init(contents: [
            .text(config, uri: params.uri, mimeType: "application/json")
        ])
    default:
        throw MCPError.invalidParams("Unknown resource: \(params.uri)")
    }
}
```

### Binary Content

```swift
case "asset://logo.png":
    let imageData = try await loadImage("logo.png")
    return .init(contents: [
        .binary(imageData, uri: params.uri, mimeType: "image/png")
    ])
```

`Resource.Content.binary` automatically base64-encodes the `Data`.

### Multiple Content Items

A single resource read can return multiple content items:

```swift
case "report://full":
    return .init(contents: [
        .text(summaryJSON, uri: "report://full/summary", mimeType: "application/json"),
        .binary(chartData, uri: "report://full/chart", mimeType: "image/png")
    ])
```

## Resource Templates

Templates expose parameterized URIs using URI template syntax:

```swift
await server.withMethodHandler(ListResourceTemplates.self) { _ in
    .init(templates: [
        Resource.Template(
            uriTemplate: "file:///{path}",
            name: "File",
            description: "Read a file by path",
            mimeType: "text/plain"
        ),
        Resource.Template(
            uriTemplate: "db://users/{userId}",
            name: "User Record",
            description: "Get user by ID",
            mimeType: "application/json"
        )
    ])
}
```

Handle template URIs in `ReadResource` by pattern matching:

```swift
await server.withMethodHandler(ReadResource.self) { params in
    if params.uri.hasPrefix("db://users/") {
        let userId = String(params.uri.dropFirst("db://users/".count))
        let user = try await fetchUser(id: userId)
        return .init(contents: [.text(user.toJSON(), uri: params.uri, mimeType: "application/json")])
    }
    // ... other resources
}
```

## Subscriptions

Allow clients to subscribe to resource updates. Requires `resources: .init(subscribe: true)` in capabilities.

### Handle Subscribe/Unsubscribe

```swift
actor ResourceState {
    var subscriptions: Set<String> = []

    func subscribe(to uri: String) { subscriptions.insert(uri) }
    func unsubscribe(from uri: String) { subscriptions.remove(uri) }
    func isSubscribed(to uri: String) -> Bool { subscriptions.contains(uri) }
}

let state = ResourceState()

await server.withMethodHandler(ResourceSubscribe.self) { params in
    await state.subscribe(to: params.uri)
    return Empty()
}

await server.withMethodHandler(ResourceUnsubscribe.self) { params in
    await state.unsubscribe(from: params.uri)
    return Empty()
}
```

### Notify on Updates

When a subscribed resource changes:

```swift
try await server.notify(ResourceUpdatedNotification.message(.init(uri: "config://app")))
```

### Notify on List Changes

When the set of available resources changes:

```swift
try await server.notify(ResourceListChangedNotification.message())
```

## URI Scheme Conventions

| Scheme | Use Case | Example |
|--------|----------|---------|
| `file://` | Filesystem resources | `file:///etc/config.yaml` |
| `config://` | Configuration data | `config://app` |
| `db://` | Database records | `db://users/123` |
| `api://` | API endpoints | `api://weather/current` |
| Custom | Domain-specific | `metrics://cpu`, `log://app` |
