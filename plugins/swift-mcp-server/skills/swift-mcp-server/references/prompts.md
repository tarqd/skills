# Prompts Reference

## Prompt Definition

Prompts are reusable templates that generate messages for LLM interactions:

```swift
Prompt(
    name: "review-code",                              // Required: unique identifier
    title: "Code Review",                              // Optional: display name
    description: "Review code for quality issues",     // Optional: description
    arguments: [                                       // Optional: parameters
        Prompt.Argument(
            name: "language",
            title: "Language",
            description: "Programming language",
            required: true
        ),
        Prompt.Argument(
            name: "style",
            title: "Review Style",
            description: "Focus area: security, performance, or general",
            required: false
        )
    ]
)
```

## Listing Prompts

```swift
await server.withMethodHandler(ListPrompts.self) { params in
    // params.cursor: String? — for pagination
    .init(prompts: [
        Prompt(name: "summarize", description: "Summarize text"),
        Prompt(name: "review-code", description: "Review code",
               arguments: [
                   .init(name: "language", description: "Programming language", required: true),
                   .init(name: "code", description: "Code to review", required: true)
               ]),
        Prompt(name: "explain-error", description: "Explain an error message",
               arguments: [
                   .init(name: "error", description: "Error message", required: true)
               ])
    ])
}
```

## Getting Prompt Messages

Return generated messages when a prompt is requested:

```swift
await server.withMethodHandler(GetPrompt.self) { params in
    // params.name: String
    // params.arguments: [String: Value]?

    switch params.name {
    case "summarize":
        return .init(
            description: "Text summarization",
            messages: [
                .user(.text(text: "Summarize the following text concisely."))
            ]
        )

    case "review-code":
        let lang = params.arguments?["language"]?.stringValue ?? "unknown"
        let code = params.arguments?["code"]?.stringValue ?? ""
        return .init(
            description: "Code review for \(lang)",
            messages: [
                .user(.text(text: """
                    Review this \(lang) code for:
                    - Correctness and potential bugs
                    - Performance issues
                    - Style and readability

                    ```\(lang)
                    \(code)
                    ```
                    """)),
                .assistant(.text(text: "I'll review this code systematically."))
            ]
        )

    case "explain-error":
        let error = params.arguments?["error"]?.stringValue ?? ""
        return .init(
            description: "Error explanation",
            messages: [
                .user(.text(text: "Explain this error and suggest fixes:\n\n\(error)"))
            ]
        )

    default:
        throw MCPError.invalidRequest("Unknown prompt: \(params.name)")
    }
}
```

## Prompt Message Types

### Roles

```swift
Prompt.Message.user(content)       // User role
Prompt.Message.assistant(content)  // Assistant role
```

### Content Types

**Text** (most common):
```swift
.text(text: "Message content")
```

`Prompt.Message.Content` conforms to `ExpressibleByStringLiteral`, so text content can use simple string syntax:

```swift
.user("Simple text message")  // Equivalent to .user(.text(text: "Simple text message"))
```

**Image**:
```swift
.image(data: base64String, mimeType: "image/png")
```

**Audio**:
```swift
.audio(data: base64String, mimeType: "audio/wav")
```

**Embedded Resource**:
```swift
.resource(
    resource: .text("Resource content", uri: "data://source", mimeType: "text/plain"),
    annotations: nil,
    _meta: nil
)
```

## Multi-Message Prompts

Create conversation-style prompts with multiple messages:

```swift
case "debug-session":
    let error = params.arguments?["error"]?.stringValue ?? ""
    return .init(
        description: "Interactive debugging session",
        messages: [
            .user(.text(text: "I'm seeing this error: \(error)")),
            .assistant(.text(text: "Let me help debug this. Can you share the relevant code?")),
            .user(.text(text: "Here's the surrounding context.")),
            .assistant(.text(text: "I'll analyze the error in context."))
        ]
    )
```

## Prompts with Embedded Resources

Include resource data directly in prompt messages:

```swift
case "analyze-data":
    let uri = params.arguments?["resourceUri"]?.stringValue ?? ""
    return .init(
        description: "Data analysis prompt",
        messages: [
            .user(.resource(
                resource: .text(dataContent, uri: uri, mimeType: "application/json")
            )),
            .user(.text(text: "Analyze the data above and provide key insights."))
        ]
    )
```

## Dynamic Prompt Lists

Notify clients when available prompts change:

```swift
try await server.notify(PromptListChangedNotification.message())
```

Requires `prompts: .init(listChanged: true)` in capabilities.
