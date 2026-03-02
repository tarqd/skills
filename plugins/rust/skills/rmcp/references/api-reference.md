# rmcp API Reference

## Feature Flags

### Core Features
| Feature | Default | Purpose |
|---------|---------|---------|
| `base64` | Yes | Base64 encoding for image content |
| `macros` | Yes | `#[tool]`, `#[prompt]`, `#[tool_router]` procedural macros |
| `server` | Yes | Server-side functionality with schema generation |
| `schemars` | Yes (via server) | JSON Schema generation for parameters |

### Client Features
| Feature | Purpose |
|---------|---------|
| `client` | Client-side handler traits and utilities |
| `reqwest` | HTTP client with rustls TLS |
| `reqwest-native-tls` | HTTP client with native TLS |
| `reqwest-tls-no-provider` | HTTP client, bring your own crypto |

### Transport Features
| Feature | Purpose |
|---------|---------|
| `transport-async-rw` | Transport from `tokio::io::{AsyncRead, AsyncWrite}` |
| `transport-io` | Standard IO transport (requires `transport-async-rw`) |
| `transport-worker` | Worker transport for background message processing |
| `transport-child-process` | Child process transport via `process-wrap` |
| `transport-streamable-http-server` | HTTP server transport with Tower |
| `transport-streamable-http-server-session` | HTTP server session handling |
| `transport-streamable-http-client` | Streamable HTTP client with SSE |
| `transport-streamable-http-client-reqwest` | HTTP client + reqwest integration |

### Additional Features
| Feature | Purpose |
|---------|---------|
| `auth` | OAuth2 authentication with authorization management |
| `elicitation` | User elicitation support |
| `tower` | Tower service trait compatibility |

### Common Feature Combinations

```toml
# Minimal server (stdio)
rmcp = { version = "0.16", features = ["server", "transport-io"] }

# Server with HTTP
rmcp = { version = "0.16", features = ["server", "transport-streamable-http-server"] }

# Client connecting to child process
rmcp = { version = "0.16", features = ["client", "transport-child-process"] }

# Client with HTTP
rmcp = { version = "0.16", features = ["client", "transport-streamable-http-client-reqwest"] }

# Full-featured
rmcp = { version = "0.16", features = ["server", "client", "transport-io", "transport-child-process", "transport-streamable-http-server", "transport-streamable-http-client-reqwest", "auth"] }
```

---

## Core Traits

### ServerHandler

The primary trait for implementing MCP servers. All methods have default implementations (returning "not supported" errors), so only override what the server supports.

```rust
pub trait ServerHandler: Send + Sync + 'static {
    // REQUIRED: Return server info and capabilities
    fn get_info(&self) -> ServerInfo;

    // Tool operations
    async fn call_tool(&self, request: CallToolRequestParams, context: RequestContext<RoleServer>) -> Result<CallToolResult, ErrorData>;
    async fn list_tools(&self, request: PaginatedRequestParams, context: RequestContext<RoleServer>) -> Result<ListToolsResult, ErrorData>;
    fn get_tool(&self, name: &str) -> Option<Tool>;  // For task support validation
    async fn enqueue_task(&self, request: CallToolRequestParams, context: RequestContext<RoleServer>) -> Result<CreateTaskResult, ErrorData>;

    // Prompt operations
    async fn get_prompt(&self, request: GetPromptRequestParams, context: RequestContext<RoleServer>) -> Result<GetPromptResult, ErrorData>;
    async fn list_prompts(&self, request: PaginatedRequestParams, context: RequestContext<RoleServer>) -> Result<ListPromptsResult, ErrorData>;

    // Resource operations
    async fn list_resources(&self, request: PaginatedRequestParams, context: RequestContext<RoleServer>) -> Result<ListResourcesResult, ErrorData>;
    async fn list_resource_templates(&self, request: PaginatedRequestParams, context: RequestContext<RoleServer>) -> Result<ListResourceTemplatesResult, ErrorData>;
    async fn read_resource(&self, request: ReadResourceRequestParams, context: RequestContext<RoleServer>) -> Result<ReadResourceResult, ErrorData>;

    // Task operations
    async fn list_tasks(&self, request: ListTasksRequestParams, context: RequestContext<RoleServer>) -> Result<ListTasksResult, ErrorData>;
    async fn get_task_info(&self, request: GetTaskInfoRequestParams, context: RequestContext<RoleServer>) -> Result<GetTaskResult, ErrorData>;
    async fn get_task_result(&self, request: GetTaskResultRequestParams, context: RequestContext<RoleServer>) -> Result<GetTaskPayloadResult, ErrorData>;
    async fn cancel_task(&self, request: CancelTaskRequestParams, context: RequestContext<RoleServer>) -> Result<CancelTaskResult, ErrorData>;

    // Notifications
    async fn on_initialized(&self, context: NotificationContext<RoleServer>);
    async fn on_cancelled(&self, params: CancelledNotificationParams, context: NotificationContext<RoleServer>);
    async fn on_progress(&self, params: ProgressNotificationParams, context: NotificationContext<RoleServer>);
    async fn on_roots_list_changed(&self, context: NotificationContext<RoleServer>);

    // Completion
    async fn complete(&self, request: CompleteRequestParams, context: RequestContext<RoleServer>) -> Result<CompleteResult, ErrorData>;
}
```

### ClientHandler

For implementing MCP clients that can respond to server requests (e.g., sampling, elicitation).

```rust
pub trait ClientHandler: Send + Sync + 'static {
    fn get_info(&self) -> ClientInfo;

    async fn create_message(&self, params: CreateMessageRequestParams, context: RequestContext<RoleClient>) -> Result<CreateMessageResult, ErrorData>;
    async fn list_roots(&self, context: RequestContext<RoleClient>) -> Result<ListRootsResult, ErrorData>;
    async fn create_elicitation(&self, request: CreateElicitationRequestParams, context: RequestContext<RoleClient>) -> Result<CreateElicitationResult, ErrorData>;

    // Notifications from server
    async fn on_logging_message(&self, params: LoggingMessageNotificationParams, context: NotificationContext<RoleClient>);
    async fn on_tool_list_changed(&self, context: NotificationContext<RoleClient>);
    async fn on_resource_list_changed(&self, context: NotificationContext<RoleClient>);
    async fn on_prompt_list_changed(&self, context: NotificationContext<RoleClient>);
}
```

**Note:** The unit type `()` implements `ClientHandler` with sensible defaults, useful for simple clients.

### ServiceExt

Extension trait providing the `serve()` method for starting services.

```rust
pub trait ServiceExt<R: ServiceRole>: Service<R> + Sized {
    async fn serve<T: IntoTransport<R>>(self, transport: T) -> Result<RunningService<R, Self>, ServiceError>;
    async fn serve_with_ct<T: IntoTransport<R>>(self, transport: T, ct: CancellationToken) -> Result<RunningService<R, Self>, ServiceError>;
}
```

---

## Key Types

### ServerInfo & ServerCapabilities

```rust
pub struct ServerInfo {
    pub protocol_version: ProtocolVersion,
    pub capabilities: ServerCapabilities,
    pub server_info: Implementation,
    pub instructions: Option<String>,
}

// Use the builder pattern:
ServerCapabilities::builder()
    .enable_tools()
    .enable_prompts()
    .enable_resources()
    .build()
```

### RunningService

Returned by `serve()`. Provides access to the peer and service lifecycle.

```rust
let service: RunningService<RoleServer, MyHandler> = handler.serve(transport).await?;

service.peer()          // &Peer<R> - send requests/notifications to remote
service.peer_info()     // Remote's ServerInfo/ClientInfo
service.is_closed()     // Check if connection closed
service.waiting().await // Block until service terminates
service.cancel().await  // Cancel and cleanup
```

### Peer

Interface for sending messages to the remote side.

```rust
// Server peer methods (send to client):
peer.create_message(params).await?;      // Request LLM sampling
peer.list_roots(params).await?;          // Request root listing

// Client peer methods (send to server):
peer.list_tools(params).await?;
peer.list_all_tools().await?;            // Auto-paginated
peer.call_tool(params).await?;
peer.list_resources(params).await?;
peer.list_all_resources().await?;        // Auto-paginated
peer.read_resource(params).await?;
peer.list_prompts(params).await?;
peer.list_all_prompts().await?;          // Auto-paginated
peer.get_prompt(params).await?;
```

### RequestContext & NotificationContext

```rust
pub struct RequestContext<R: ServiceRole> {
    pub ct: CancellationToken,   // Check ct.is_cancelled() for cooperative cancellation
    pub id: RequestId,
    pub meta: Meta,
    pub extensions: Extensions,
    pub peer: Peer<R>,           // Send messages back
}

pub struct NotificationContext<R: ServiceRole> {
    pub meta: Meta,
    pub extensions: Extensions,
    pub peer: Peer<R>,
}
```

### CallToolResult & Content

```rust
// Success with text
CallToolResult::success(vec![Content::text("result")])

// Success with image
CallToolResult::success(vec![Content::image(base64_data, "image/png")])

// Error
CallToolResult::error(vec![Content::text("something went wrong")])
```

### ErrorData

```rust
pub struct ErrorData {
    pub code: i32,
    pub message: String,
    pub data: Option<serde_json::Value>,
}
```

---

## Procedural Macros

### #[tool] - Define a Tool

```rust
#[tool(description = "Calculate sum of two numbers")]
fn sum(&self, Parameters(req): Parameters<SumRequest>) -> Result<CallToolResult, ErrorData> { }

// With all options:
#[tool(
    name = "custom_name",
    description = "Tool description",
    annotations(
        title = "Human Title",
        read_only_hint = true,
        destructive_hint = false,
        idempotent_hint = true,
        open_world_hint = false
    ),
    execution(task_support = "optional")  // "forbidden" | "optional" | "required"
)]
async fn my_tool(&self, params: Parameters<MyInput>) -> Result<Json<MyOutput>, String> { }
```

**Supported return types:**
- `Result<CallToolResult, ErrorData>` - Full control
- `Result<Json<T>, ErrorData>` - Structured JSON with auto schema
- `Result<String, String>` - Simple text
- `String` - Infallible text
- Any type implementing `IntoCallToolResult`

### #[tool_router] - Register Tools

Place on an `impl` block containing `#[tool]` methods. Generates a `tool_router()` constructor.

```rust
#[tool_router]
impl MyServer {
    fn new() -> Self {
        Self { tool_router: Self::tool_router() }
    }

    #[tool(description = "...")]
    fn my_tool(&self, params: Parameters<Input>) -> String { }
}
```

### #[tool_handler] - Wire Router to ServerHandler

```rust
#[tool_handler]
impl ServerHandler for MyServer {
    fn get_info(&self) -> ServerInfo { /* ... */ }
    // call_tool and list_tools auto-implemented via self.tool_router
}
```

### #[prompt] / #[prompt_router] / #[prompt_handler]

Identical pattern to tools but for prompts:

```rust
#[prompt_router]
impl MyServer {
    #[prompt(name = "greeting")]
    async fn greeting(&self) -> Vec<PromptMessage> {
        vec![PromptMessage::new_text(PromptMessageRole::User, "Hello!")]
    }

    #[prompt(name = "code_review")]
    async fn code_review(&self, Parameters(args): Parameters<ReviewArgs>) -> Result<GetPromptResult, ErrorData> { }
}

#[prompt_handler]
impl ServerHandler for MyServer { }
```

### #[task_handler]

Generates `enqueue_task`, `list_tasks`, `get_task_info`, `get_task_result`, `cancel_task` implementations. Requires handler to have an `OperationProcessor` field.

```rust
#[task_handler]
impl ServerHandler for MyServer {
    // Auto-implements task-related methods using self.processor
}
```

### Wrapper Types

**`Parameters<T>`** - Extracts and deserializes tool/prompt arguments:
```rust
#[tool(description = "...")]
fn my_tool(&self, Parameters(input): Parameters<MyInput>) -> String {
    input.field  // Directly access deserialized fields
}
```

**`Json<T>`** - Wraps output for structured JSON with auto schema:
```rust
#[tool(description = "...")]
fn my_tool(&self) -> Result<Json<MyOutput>, String> {
    Ok(Json(MyOutput { field: "value".into() }))
}
```

---

## Transport Layer

### Transport Trait

```rust
pub trait Transport<R: ServiceRole>: Send {
    type Error: std::error::Error + Send + Sync + 'static;
    fn send(&mut self, item: TxJsonRpcMessage<R>) -> impl Future<Output = Result<(), Self::Error>> + Send + 'static;
    fn receive(&mut self) -> impl Future<Output = Option<RxJsonRpcMessage<R>>> + Send;
    fn close(&mut self) -> impl Future<Output = Result<(), Self::Error>> + Send;
}
```

### Built-in Transports

| Transport | Direction | Feature Flag | Usage |
|-----------|-----------|--------------|-------|
| `stdio()` | Server | `transport-io` | `handler.serve(stdio()).await?` |
| `TokioChildProcess` | Client | `transport-child-process` | `().serve(TokioChildProcess::new(cmd)?).await?` |
| `StreamableHttpClientTransport` | Client | `transport-streamable-http-client-reqwest` | HTTP with SSE streaming |
| `StreamableHttpService` | Server | `transport-streamable-http-server` | Tower-compatible HTTP server |

### Automatic Conversions (IntoTransport)

Any of these can be passed to `serve()`:
- `tokio::net::TcpStream` → auto-converts via AsyncRead/AsyncWrite
- `tokio::net::UnixStream` → auto-converts
- `(AsyncRead, AsyncWrite)` tuple → auto-converts
- `(Sink, Stream)` tuple → auto-converts
- Any `Transport<R>` impl → passthrough

---

## Task Management System

For long-running tool executions:

```rust
use rmcp::task_manager::{OperationProcessor, OperationMessage, OperationDescriptor};

struct MyServer {
    processor: Arc<Mutex<OperationProcessor>>,
}

// The #[task_handler] macro wires this up automatically
```

### Task Lifecycle
`Working` → `Completed` | `Failed` | `Cancelled`

### Task Status Values
- `Working` - In progress
- `InputRequired` - Needs user elicitation
- `Completed` - Success
- `Failed` - Error
- `Cancelled` - Cancelled by client

---

## Service Lifecycle

### Server Startup
1. Create handler implementing `ServerHandler`
2. Call `handler.serve(transport).await?`
3. SDK awaits `InitializeRequest` from client
4. Responds with `ServerInfo` (capabilities, version)
5. Awaits `InitializedNotification`
6. Returns `RunningService<RoleServer, H>`

### Client Startup
1. Create handler implementing `ClientHandler` (or use `()`)
2. Call `handler.serve(transport).await?`
3. SDK sends `InitializeRequest` with client info
4. Awaits `InitializeResult` from server
5. Sends `InitializedNotification`
6. Returns `RunningService<RoleClient, H>`

### Shutdown
- `service.cancel().await` - Cancel and cleanup
- `service.waiting().await` - Wait for natural termination
- `service.close()` - Graceful close
- Drop guard auto-cancels if `RunningService` is dropped

---

## Error Handling

### ErrorData (Protocol Level)
```rust
ErrorData {
    code: -1,
    message: "Tool not found".into(),
    data: None,
}
```

### ServiceError (Transport/Service Level)
```rust
pub enum ServiceError {
    McpError(ErrorData),
    TransportSend(DynamicTransportError),
    TransportClosed,
    UnexpectedResponse,
    Cancelled { reason: Option<String> },
    Timeout { timeout: Duration },
}
```

### Tool Error Patterns
```rust
// Return ErrorData directly
#[tool(description = "...")]
async fn my_tool(&self) -> Result<CallToolResult, ErrorData> {
    Err(ErrorData { code: -1, message: "failed".into(), data: None })
}

// Return String error (auto-converts)
#[tool(description = "...")]
async fn my_tool(&self) -> Result<String, String> {
    Err("something went wrong".into())
}

// Return error content in CallToolResult
Ok(CallToolResult::error(vec![Content::text("error details")]))
```
