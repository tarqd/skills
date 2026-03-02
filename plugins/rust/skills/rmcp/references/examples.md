# rmcp Examples

Complete working examples for common MCP patterns.

## Minimal Stdio Server

The simplest possible MCP server with tools:

```rust
use rmcp::{
    ServerHandler, ServiceExt,
    handler::server::{router::tool::ToolRouter, wrapper::Parameters},
    model::*,
    schemars, tool, tool_handler, tool_router,
    transport::io::stdio,
};

#[derive(Debug, serde::Deserialize, schemars::JsonSchema)]
struct SumRequest {
    a: i32,
    b: i32,
}

#[derive(Clone)]
struct Calculator {
    tool_router: ToolRouter<Calculator>,
}

#[tool_router]
impl Calculator {
    fn new() -> Self {
        Self {
            tool_router: Self::tool_router(),
        }
    }

    #[tool(description = "Calculate the sum of two numbers")]
    fn sum(&self, Parameters(SumRequest { a, b }): Parameters<SumRequest>) -> String {
        (a + b).to_string()
    }

    #[tool(description = "Calculate the difference of two numbers")]
    fn subtract(&self, Parameters(SumRequest { a, b }): Parameters<SumRequest>) -> String {
        (a - b).to_string()
    }
}

#[tool_handler]
impl ServerHandler for Calculator {
    fn get_info(&self) -> ServerInfo {
        ServerInfo {
            protocol_version: ProtocolVersion::V_2024_11_05,
            capabilities: ServerCapabilities::builder()
                .enable_tools()
                .build(),
            server_info: Implementation::from_build_env(),
            instructions: Some("A simple calculator".to_string()),
        }
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();
    let service = Calculator::new().serve(stdio()).await?;
    service.waiting().await?;
    Ok(())
}
```

**Cargo.toml:**
```toml
[dependencies]
rmcp = { version = "0.16", features = ["server", "transport-io"] }
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
schemars = "1"
anyhow = "1"
tracing-subscriber = "0.3"
```

---

## Server with Tools, Prompts, and Resources

A full-featured server demonstrating all capability types:

```rust
use std::sync::Arc;
use rmcp::{
    ErrorData as McpError, RoleServer, ServerHandler, ServiceExt,
    handler::server::{
        router::{prompt::PromptRouter, tool::ToolRouter},
        wrapper::Parameters,
    },
    model::*,
    prompt, prompt_handler, prompt_router, schemars,
    service::RequestContext,
    tool, tool_handler, tool_router,
    transport::io::stdio,
};
use tokio::sync::Mutex;

#[derive(Debug, serde::Deserialize, schemars::JsonSchema)]
struct CounterAnalysisArgs {
    analysis_type: Option<String>,
}

#[derive(Clone)]
struct Counter {
    counter: Arc<Mutex<i32>>,
    tool_router: ToolRouter<Counter>,
    prompt_router: PromptRouter<Counter>,
}

#[tool_router]
impl Counter {
    fn new() -> Self {
        Self {
            counter: Arc::new(Mutex::new(0)),
            tool_router: Self::tool_router(),
            prompt_router: Self::prompt_router(),
        }
    }

    #[tool(description = "Increment the counter by 1")]
    async fn increment(&self) -> Result<CallToolResult, McpError> {
        let mut counter = self.counter.lock().await;
        *counter += 1;
        Ok(CallToolResult::success(vec![Content::text(counter.to_string())]))
    }

    #[tool(description = "Decrement the counter by 1")]
    async fn decrement(&self) -> Result<CallToolResult, McpError> {
        let mut counter = self.counter.lock().await;
        *counter -= 1;
        Ok(CallToolResult::success(vec![Content::text(counter.to_string())]))
    }

    #[tool(description = "Get the current counter value")]
    async fn get_value(&self) -> Result<CallToolResult, McpError> {
        let counter = self.counter.lock().await;
        Ok(CallToolResult::success(vec![Content::text(counter.to_string())]))
    }
}

#[prompt_router]
impl Counter {
    #[prompt(name = "counter_analysis")]
    async fn counter_analysis(
        &self,
        Parameters(args): Parameters<CounterAnalysisArgs>,
        _ctx: RequestContext<RoleServer>,
    ) -> Result<Vec<PromptMessage>, McpError> {
        let current_value = *self.counter.lock().await;
        let analysis_type = args.analysis_type.unwrap_or("summary".to_string());
        let prompt = format!(
            "Analyze counter value {} with analysis type: {}",
            current_value, analysis_type
        );
        Ok(vec![PromptMessage {
            role: PromptMessageRole::User,
            content: PromptMessageContent::text(prompt),
        }])
    }
}

#[tool_handler]
#[prompt_handler]
impl ServerHandler for Counter {
    fn get_info(&self) -> ServerInfo {
        ServerInfo {
            protocol_version: ProtocolVersion::V_2024_11_05,
            capabilities: ServerCapabilities::builder()
                .enable_tools()
                .enable_prompts()
                .enable_resources()
                .build(),
            server_info: Implementation::from_build_env(),
            instructions: Some("Counter server with tools, prompts, and resources".to_string()),
        }
    }

    async fn list_resources(
        &self,
        _request: PaginatedRequestParams,
        _context: RequestContext<RoleServer>,
    ) -> Result<ListResourcesResult, McpError> {
        Ok(ListResourcesResult {
            resources: vec![Resource {
                uri: "counter://current".into(),
                name: "Current Counter Value".into(),
                description: Some("The current value of the counter".into()),
                mime_type: Some("text/plain".into()),
                annotations: None,
                size: None,
            }],
            next_cursor: None,
        })
    }

    async fn read_resource(
        &self,
        request: ReadResourceRequestParams,
        _context: RequestContext<RoleServer>,
    ) -> Result<ReadResourceResult, McpError> {
        if request.uri.as_str() == "counter://current" {
            let value = *self.counter.lock().await;
            Ok(ReadResourceResult {
                contents: vec![ResourceContents::text(
                    request.uri,
                    value.to_string(),
                )],
            })
        } else {
            Err(McpError::resource_not_found("unknown resource", None))
        }
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();
    let service = Counter::new().serve(stdio()).await?;
    service.waiting().await?;
    Ok(())
}
```

---

## Structured Output Server

Tools returning structured JSON with automatic schema generation:

```rust
use rmcp::{
    ServerHandler, ServiceExt,
    handler::server::{router::tool::ToolRouter, wrapper::{Json, Parameters}},
    model::*,
    schemars, tool, tool_handler, tool_router,
    transport::io::stdio,
};

#[derive(Debug, serde::Deserialize, schemars::JsonSchema)]
struct WeatherRequest {
    city: String,
}

#[derive(Debug, serde::Serialize, schemars::JsonSchema)]
struct WeatherResponse {
    temperature: f64,
    description: String,
    humidity: u32,
    wind_speed: f64,
}

#[derive(Clone)]
struct WeatherServer {
    tool_router: ToolRouter<WeatherServer>,
}

#[tool_router]
impl WeatherServer {
    fn new() -> Self {
        Self { tool_router: Self::tool_router() }
    }

    #[tool(name = "get_weather", description = "Get weather for a city")]
    async fn get_weather(
        &self,
        Parameters(req): Parameters<WeatherRequest>,
    ) -> Result<Json<WeatherResponse>, String> {
        Ok(Json(WeatherResponse {
            temperature: 22.5,
            description: format!("Sunny in {}", req.city),
            humidity: 65,
            wind_speed: 12.5,
        }))
    }
}

#[tool_handler]
impl ServerHandler for WeatherServer {
    fn get_info(&self) -> ServerInfo {
        ServerInfo {
            protocol_version: ProtocolVersion::V_2024_11_05,
            capabilities: ServerCapabilities::builder().enable_tools().build(),
            server_info: Implementation::from_build_env(),
            instructions: None,
        }
    }
}
```

---

## Client Connecting to a Server

```rust
use anyhow::Result;
use rmcp::{
    ServiceExt,
    model::{CallToolRequestParams, GetPromptRequestParams, ReadResourceRequestParams},
    object,
    transport::{ConfigureCommandExt, TokioChildProcess},
};
use tokio::process::Command;

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();

    // Connect to a server via child process
    let client = ()
        .serve(TokioChildProcess::new(Command::new("my-mcp-server").configure(
            |cmd| { cmd.arg("--some-flag"); },
        ))?)
        .await?;

    // Check server info
    let server_info = client.peer_info();
    tracing::info!("Connected to: {server_info:#?}");

    // List and call tools
    let tools = client.list_all_tools().await?;
    tracing::info!("Tools: {tools:#?}");

    let result = client
        .call_tool(CallToolRequestParams {
            meta: None,
            name: "sum".into(),
            arguments: Some(object!({ "a": 5, "b": 3 })),
            task: None,
        })
        .await?;
    tracing::info!("Result: {result:#?}");

    // List and read resources
    let resources = client.list_all_resources().await?;
    let resource = client
        .read_resource(ReadResourceRequestParams {
            meta: None,
            uri: "counter://current".into(),
        })
        .await?;

    // List and get prompts
    let prompts = client.list_all_prompts().await?;
    let prompt = client
        .get_prompt(GetPromptRequestParams {
            meta: None,
            name: "counter_analysis".into(),
            arguments: Some(object!({ "analysis_type": "detailed" })),
        })
        .await?;

    client.cancel().await?;
    Ok(())
}
```

**Cargo.toml:**
```toml
[dependencies]
rmcp = { version = "0.16", features = ["client", "transport-child-process"] }
tokio = { version = "1", features = ["full"] }
anyhow = "1"
tracing = "0.1"
tracing-subscriber = "0.3"
```

---

## TCP Transport

Server and client communicating over TCP:

```rust
use rmcp::ServiceExt;
use rmcp::service::{serve_server, serve_client};

async fn server(listener: tokio::net::TcpListener) -> anyhow::Result<()> {
    while let Ok((stream, addr)) = listener.accept().await {
        tracing::info!("Connection from: {addr}");
        tokio::spawn(async move {
            let server = serve_server(Calculator::new(), stream).await?;
            server.waiting().await?;
            anyhow::Ok(())
        });
    }
    Ok(())
}

async fn client() -> anyhow::Result<()> {
    let stream = tokio::net::TcpStream::connect("127.0.0.1:8001").await?;
    let client = serve_client((), stream).await?;
    let tools = client.peer().list_tools(Default::default()).await?;
    tracing::info!("{tools:#?}");
    client.cancel().await?;
    Ok(())
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let listener = tokio::net::TcpListener::bind("127.0.0.1:8001").await?;
    tokio::spawn(server(listener));
    tokio::time::sleep(std::time::Duration::from_millis(100)).await;
    client().await
}
```

---

## HTTP Streaming Server (with Hyper)

```rust
use rmcp::{
    ServiceExt,
    transport::streamable_http_server::{
        StreamableHttpService, session::LocalSessionManager,
    },
};

let service = StreamableHttpService::new(
    || Ok(Counter::new()),            // Factory: new handler per session
    LocalSessionManager::default().into(),
    Default::default(),
);

// Use with hyper or axum
let listener = tokio::net::TcpListener::bind("127.0.0.1:3000").await?;
axum::serve(listener, service.into_make_service()).await?;
```

---

## Client with Sampling Handler

A client that responds to server sampling requests:

```rust
use rmcp::{
    RoleClient, ServiceExt,
    handler::client::ClientHandler,
    model::*,
    service::RequestContext,
    transport::{ConfigureCommandExt, TokioChildProcess},
};
use tokio::process::Command;

struct SamplingClient;

impl ClientHandler for SamplingClient {
    fn get_info(&self) -> ClientInfo {
        ClientInfo::default()
    }

    async fn create_message(
        &self,
        params: CreateMessageRequestParams,
        _context: RequestContext<RoleClient>,
    ) -> Result<CreateMessageResult, ErrorData> {
        // Process sampling request from server
        let response_text = format!("Mock response to: {:?}", params.messages);

        Ok(CreateMessageResult {
            message: SamplingMessage::assistant_text(response_text),
            model: "mock-model".to_string(),
            stop_reason: Some(CreateMessageResult::STOP_REASON_END_TURN.to_string()),
        })
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let client = SamplingClient
        .serve(TokioChildProcess::new(Command::new("my-server"))?)
        .await?;

    // Server can now call client.peer.create_message() to request sampling
    client.waiting().await?;
    Ok(())
}
```

---

## In-Memory Testing

Test servers without real transport:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use rmcp::ServiceExt;

    #[tokio::test]
    async fn test_server() {
        let (client_transport, server_transport) = tokio::io::duplex(4096);

        // Start server
        let server = tokio::spawn(async move {
            let service = Counter::new().serve(server_transport).await.unwrap();
            service.waiting().await;
        });

        // Connect client
        let client = ().serve(client_transport).await.unwrap();

        // Test tools
        let tools = client.list_all_tools().await.unwrap();
        assert!(!tools.is_empty());

        let result = client
            .call_tool(CallToolRequestParams {
                meta: None,
                name: "increment".into(),
                arguments: None,
                task: None,
            })
            .await
            .unwrap();

        assert!(result.is_success());

        client.cancel().await.unwrap();
    }
}
```

---

## OAuth Client

Connect to an authenticated MCP server:

```rust
use rmcp::{
    ServiceExt,
    model::ClientInfo,
    transport::{
        StreamableHttpClientTransport,
        auth::{AuthClient, OAuthState},
        streamable_http_client::StreamableHttpClientTransportConfig,
    },
};

let server_url = "http://127.0.0.1:3000/mcp";
let redirect_uri = "http://127.0.0.1:8080/callback";

// Initialize OAuth
let mut oauth_state = OAuthState::new(server_url, None).await?;
oauth_state
    .start_authorization_with_metadata_url(&[], redirect_uri, Some("My Client"), None)
    .await?;

let auth_url = oauth_state.get_authorization_url().await?;
println!("Visit: {auth_url}");

// After user authorizes and callback received:
oauth_state.handle_callback(&auth_code, &csrf_token).await?;

// Create authenticated transport
let am = oauth_state.into_authorization_manager().unwrap();
let client = AuthClient::new(reqwest::Client::default(), am);
let transport = StreamableHttpClientTransport::with_client(
    client,
    StreamableHttpClientTransportConfig::with_uri(server_url),
);

let service = ClientInfo::default().serve(transport).await?;
let tools = service.peer().list_all_tools().await?;
```

---

## Managing Multiple Clients

```rust
use std::collections::HashMap;
use rmcp::ServiceExt;

let mut clients = HashMap::new();

for (id, cmd) in server_commands.iter().enumerate() {
    let client = ().serve(TokioChildProcess::new(cmd.clone())?).await?;
    clients.insert(id, client.into_dyn());  // Dynamic dispatch
}

// Call tools on all clients
for (id, client) in &clients {
    let tools = client.peer().list_all_tools().await?;
    println!("Server {id}: {} tools", tools.len());
}

// Cleanup
for (_, client) in clients {
    client.cancel().await?;
}
```
