---
name: rmcp - Rust MCP SDK
description: >
  This skill should be used when the user asks to "build an MCP server in Rust",
  "create an MCP client in Rust", "use the rmcp crate", "implement MCP tools in Rust",
  "add MCP transport in Rust", "write a Rust MCP tool", "connect to an MCP server from Rust",
  "implement ServerHandler", "use #[tool] macro", "MCP prompts in Rust", "MCP resources in Rust",
  "rmcp task system", or mentions rmcp, Rust MCP SDK, or Model Context Protocol with Rust.
  Provides comprehensive guidance for building MCP servers and clients using the official Rust SDK.
version: 0.1.0
---

# rmcp - Official Rust SDK for Model Context Protocol

The `rmcp` crate is the official Rust implementation of the Model Context Protocol (MCP).
It enables building MCP servers that expose tools, prompts, and resources to AI assistants,
and MCP clients that connect to and interact with such servers.

**Source:** <https://github.com/modelcontextprotocol/rust-sdk>
**Local clone:** `/Users/tarq/Development/rust-sdk` (with generated docs at `target/doc/rmcp/`)

## Quick Start

### Minimal Server

```rust
use rmcp::{
    ServerHandler, ServiceExt,
    handler::server::{router::tool::ToolRouter, wrapper::Parameters},
    model::*,
    schemars, tool, tool_handler, tool_router,
    transport::io::stdio,
};

#[derive(Debug, serde::Deserialize, schemars::JsonSchema)]
struct AddRequest { a: i32, b: i32 }

#[derive(Clone)]
struct Calculator { tool_router: ToolRouter<Calculator> }

#[tool_router]
impl Calculator {
    fn new() -> Self { Self { tool_router: Self::tool_router() } }

    #[tool(description = "Add two numbers")]
    fn add(&self, Parameters(AddRequest { a, b }): Parameters<AddRequest>) -> String {
        (a + b).to_string()
    }
}

#[tool_handler]
impl ServerHandler for Calculator {
    fn get_info(&self) -> ServerInfo {
        ServerInfo {
            protocol_version: ProtocolVersion::V_2024_11_05,
            capabilities: ServerCapabilities::builder().enable_tools().build(),
            server_info: Implementation::from_build_env(),
            instructions: Some("A calculator server".into()),
        }
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let service = Calculator::new().serve(stdio()).await?;
    service.waiting().await?;
    Ok(())
}
```

### Minimal Client

```rust
use rmcp::{ServiceExt, model::CallToolRequestParams, object,
    transport::{ConfigureCommandExt, TokioChildProcess}};
use tokio::process::Command;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let client = ().serve(TokioChildProcess::new(
        Command::new("my-mcp-server").configure(|cmd| { cmd.arg("--flag"); })
    )?).await?;

    let tools = client.list_all_tools().await?;
    let result = client.call_tool(CallToolRequestParams {
        meta: None, name: "add".into(),
        arguments: Some(object!({ "a": 5, "b": 3 })), task: None,
    }).await?;

    client.cancel().await?;
    Ok(())
}
```

## Core Architecture

### Server Pattern

1. Define a handler struct with router fields
2. Use `#[tool_router]` on an `impl` block containing `#[tool]` methods
3. Optionally use `#[prompt_router]` for prompts
4. Use `#[tool_handler]` and `#[prompt_handler]` on the `ServerHandler` impl
5. Start with `handler.serve(transport).await?`

### Client Pattern

1. Use `()` as handler for simple clients (implements `ClientHandler` with defaults)
2. Implement `ClientHandler` to handle sampling requests from servers
3. Start with `handler.serve(transport).await?`
4. Interact via convenience methods on `RunningService` (e.g. `client.list_all_tools()`) which delegate to `client.peer()`

### Key Traits

| Trait | Purpose |
|-------|---------|
| `ServerHandler` | Implement to create MCP servers. Override `get_info()` + capability methods |
| `ClientHandler` | Implement to handle server-initiated requests (sampling, elicitation). `()` provides defaults |
| `ServiceExt` | Extension trait providing `.serve(transport)` to start services |
| `Transport` | Abstraction over communication channels. Many types auto-convert |

## Cargo.toml Feature Flags

| Use Case | Features |
|----------|----------|
| Stdio server | `["server", "transport-io"]` |
| HTTP server | `["server", "transport-streamable-http-server"]` |
| Child process client | `["client", "transport-child-process"]` |
| HTTP client | `["client", "transport-streamable-http-client-reqwest"]` |
| With OAuth | Add `"auth"` to any client config |

## Defining Tools

Use the `#[tool]` attribute macro on methods inside a `#[tool_router]` impl block:

```rust
#[tool_router]
impl MyServer {
    // Simple: returns String
    #[tool(description = "Greet someone")]
    fn greet(&self, Parameters(req): Parameters<GreetRequest>) -> String { }

    // Full control: returns CallToolResult
    #[tool(description = "Complex operation")]
    async fn complex(&self, params: Parameters<Input>) -> Result<CallToolResult, ErrorData> { }

    // Structured JSON output with auto schema
    #[tool(name = "get_weather", description = "Get weather")]
    async fn weather(&self, params: Parameters<WeatherReq>) -> Result<Json<WeatherResp>, String> { }

    // With annotations
    #[tool(description = "Read-only query", annotations(read_only_hint = true, idempotent_hint = true))]
    async fn query(&self, params: Parameters<QueryReq>) -> Result<CallToolResult, ErrorData> { }
}
```

**Parameter types** must derive `Deserialize` and `schemars::JsonSchema`.
**`Parameters<T>`** extracts and deserializes tool arguments automatically.
**`Json<T>`** wraps output for structured JSON with auto-generated output schema.

## Defining Prompts

```rust
#[prompt_router]
impl MyServer {
    #[prompt(name = "code_review")]
    async fn code_review(
        &self,
        Parameters(args): Parameters<ReviewArgs>,
        _ctx: RequestContext<RoleServer>,
    ) -> Result<GetPromptResult, ErrorData> { }
}

#[prompt_handler]
impl ServerHandler for MyServer { /* ... */ }
```

## Transport Options

| Transport | Direction | How to Use |
|-----------|-----------|------------|
| `stdio()` | Server | `handler.serve(stdio()).await?` |
| `TokioChildProcess` | Client | `().serve(TokioChildProcess::new(cmd)?).await?` |
| `TcpStream` | Both | Pass directly to `serve()` — auto-converts |
| `UnixStream` | Both | Pass directly to `serve()` — auto-converts |
| `tokio::io::duplex()` | Testing | In-memory bidirectional — auto-converts |
| `StreamableHttpService` | Server | Tower-compatible HTTP with sessions |
| `StreamableHttpClientTransport` | Client | HTTP with SSE streaming |
| Custom `Sink + Stream` | Both | Pass tuple or combined type to `serve()` |

Any `AsyncRead + AsyncWrite`, `Sink + Stream`, or `Transport<R>` implementor can be passed to `serve()` via the `IntoTransport` trait.

## RunningService API

After `serve()` returns a `RunningService`:

```rust
let service = handler.serve(transport).await?;

service.peer()              // &Peer<R> — send requests to remote
service.peer_info()         // Remote's ServerInfo or ClientInfo
service.is_closed()         // Check if connection closed
service.waiting().await     // Block until service terminates
service.cancel().await      // Cancel and cleanup
```

**Client peer methods:** `list_all_tools()`, `call_tool()`, `list_all_resources()`, `read_resource()`, `list_all_prompts()`, `get_prompt()`

## Testing

Use `tokio::io::duplex()` for in-memory testing without real transport:

```rust
let (client_io, server_io) = tokio::io::duplex(4096);
let server = tokio::spawn(async { MyServer::new().serve(server_io).await?.waiting().await; Ok(()) });
let client = ().serve(client_io).await?;
// ... test tools, prompts, resources ...
client.cancel().await?;
```

## Task System (Long-Running Operations)

For tools that take a long time, use the task system with `OperationProcessor`:

```rust
use rmcp::task_manager::{OperationProcessor, OperationMessage};

struct MyServer {
    processor: Arc<Mutex<OperationProcessor>>,
    tool_router: ToolRouter<MyServer>,
}

#[task_handler]  // Auto-implements enqueue_task, list_tasks, get_task_info, etc.
#[tool_handler]
impl ServerHandler for MyServer { /* ... */ }
```

Mark tools as task-capable: `#[tool(execution(task_support = "optional"))]`

## Additional Resources

### Reference Files

For detailed API documentation including all traits, types, and macros:
- **`references/api-reference.md`** — Complete API reference with feature flags, trait signatures, macro options, transport details, error handling patterns

### Examples

For complete working code examples:
- **`references/examples.md`** — Minimal server, full-featured server, structured output, client, TCP, HTTP streaming, sampling handler, OAuth, in-memory testing, managing multiple clients

### Local Source & Docs

The rmcp source is cloned at `/Users/tarq/Development/rust-sdk/`:
- Generated HTML docs: `target/doc/rmcp/index.html`
- Examples directory: `examples/` (servers, clients, transport, integrations)
- Crate source: `crates/rmcp/src/`
