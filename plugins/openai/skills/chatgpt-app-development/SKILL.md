---
name: ChatGPT App Development
description: This skill should be used when the user asks to "build a ChatGPT app", "create a ChatGPT plugin", "implement MCP server for ChatGPT", "build ChatGPT UI widget", "add OAuth to ChatGPT app", "use window.openai API", "create ChatGPT component", "implement tool for ChatGPT", or mentions ChatGPT Apps SDK, skybridge, or widget development for ChatGPT.
version: 0.1.0
---

# ChatGPT App Development

Build apps that extend ChatGPT using the Apps SDK. Apps combine an MCP server (tools and data), UI widgets (rendered in iframes), and structured responses that the model can read and act upon.

## Architecture Overview

A ChatGPT app has three components:

1. **MCP Server** - Exposes tools via Model Context Protocol, handles authentication, returns structured data
2. **UI Widgets** - HTML/JS bundles rendered in sandboxed iframes within ChatGPT conversations
3. **Model Integration** - ChatGPT decides when to invoke tools based on metadata and user intent

Data flows: User request → Model selects tool → MCP server executes → Returns `structuredContent` + `_meta` → Widget renders UI

## MCP Server Essentials

### Tool Registration

Register tools with JSON schemas and metadata:

```ts
server.registerTool(
  "show-board",
  {
    title: "Show Kanban Board",
    inputSchema: { workspace: z.string() },
    _meta: {
      "openai/outputTemplate": "ui://widget/board.html",
      "openai/toolInvocation/invoking": "Loading board...",
      "openai/toolInvocation/invoked": "Board ready"
    }
  },
  async ({ workspace }) => ({
    structuredContent: boardSummary,    // Model + widget sees this
    content: [{ type: "text", text: "Drag cards to update" }],
    _meta: { fullData: allTasks }       // Widget-only, hidden from model
  })
);
```

### Tool Response Structure

- **`structuredContent`** - Concise JSON for model and widget (keep under 4k tokens)
- **`content`** - Optional markdown/text narration
- **`_meta`** - Large or sensitive data for widget only (model never sees this)

### Tool Annotations

Required annotations for ChatGPT's safety system:

```json
{
  "annotations": {
    "readOnlyHint": true,      // Required: read-only operation
    "destructiveHint": false,  // Required: deletes/overwrites data
    "openWorldHint": false     // Required: publishes externally
  }
}
```

### Component Templates

Register UI templates with `text/html+skybridge` MIME type:

```ts
server.registerResource(
  "widget",
  "ui://widget/board.html",
  {},
  async () => ({
    contents: [{
      uri: "ui://widget/board.html",
      mimeType: "text/html+skybridge",
      text: `<div id="root"></div><script type="module" src="..."></script>`,
      _meta: {
        "openai/widgetPrefersBorder": true,
        "openai/widgetCSP": {
          connect_domains: ["https://api.example.com"],
          resource_domains: ["https://*.oaistatic.com"]
        }
      }
    }]
  })
);
```

## Widget Development

### The `window.openai` API

Widgets communicate with ChatGPT through the injected `window.openai` bridge:

**Reading Data:**
- `window.openai.toolInput` - Arguments passed to the tool
- `window.openai.toolOutput` - The `structuredContent` from server
- `window.openai.toolResponseMetadata` - The `_meta` payload
- `window.openai.widgetState` - Persisted UI state

**Actions:**
- `callTool(name, args)` - Invoke another MCP tool
- `sendFollowUpMessage({ prompt })` - Insert a message into conversation
- `uploadFile(file)` - Upload PNG/JPEG/WebP images
- `getFileDownloadUrl({ fileId })` - Get temporary download URL
- `requestDisplayMode("pip" | "fullscreen")` - Change layout
- `setWidgetState(state)` - Persist UI state (shown to model)

**Context:**
- `theme` - Current visual theme
- `locale` - User's BCP 47 locale
- `displayMode` - Current display context
- `maxHeight` - Maximum widget height

### State Management

Three state categories:

| Type | Owner | Lifetime | Example |
|------|-------|----------|---------|
| Business | MCP Server | Persistent | Tasks, documents |
| UI | Widget | Message-scoped | Selected items, expanded panels |
| Cross-session | Your backend | Persistent | Saved filters, preferences |

Persist UI state with `setWidgetState()` - anything passed is visible to the model. Keep payloads under 4k tokens.

### Display Modes

Request layout changes with `requestDisplayMode()`:
- **inline** - Default conversation view
- **pip** - Picture-in-picture sidebar
- **fullscreen** - Maximum space for complex UIs

Mobile may coerce pip to fullscreen.

## Authentication

Apps requiring user data must implement OAuth 2.1:

### Required Endpoints

1. **Protected Resource Metadata** at `/.well-known/oauth-protected-resource`:
```json
{
  "resource": "https://api.example.com",
  "authorization_servers": ["https://auth.example.com"],
  "scopes_supported": ["read", "write"]
}
```

2. **Authorization Server** with discovery document, supporting:
   - Dynamic client registration
   - PKCE with S256 challenge method
   - Standard token endpoints

### Security Scheme Declaration

```json
"_meta": {
  "securitySchemes": [
    { "type": "oauth2", "scopes": ["read", "write"] }
  ]
}
```

Use `noauth` for anonymous access, `oauth2` for authenticated endpoints.

### Token Verification

The MCP server must verify every request:
- Validate JWT signature via JWKS
- Check `iss`, `aud`, `exp`, `nbf` claims
- Confirm required scopes
- Return `401` with `WWW-Authenticate` header on failure

Trigger OAuth UI by returning `_meta["mcp/www_authenticate"]` with error details.

## Security Requirements

- Never embed API keys or tokens in `structuredContent`, `content`, `_meta`, or widget state
- Enforce authorization server-side, not via client hints
- Don't trust `userAgent` or `userLocation` for authorization
- Mark destructive operations with `destructiveHint: true`
- Configure CSP allowlists in widget metadata

## Build & Deploy

### Bundle Widgets

```bash
esbuild src/component.tsx --bundle --format=esm --outfile=dist/component.js
```

### Local Testing

1. Start MCP server: `node dist/index.js`
2. Use ngrok for HTTPS: `ngrok http 3000`
3. Test with MCP Inspector at `http://localhost:3000/mcp`

### Production Deployment

Deploy to HTTPS hosts with low latency (Cloudflare Workers, Vercel, Fly.io). ChatGPT requires HTTPS for all connections.

## Submission Guidelines

Apps must:
- Provide functionality not natively in ChatGPT
- Demonstrate clear purpose and user value
- Implement proper tool annotations
- Handle errors gracefully
- Respect user privacy

Prohibited: digital subscriptions, adult content, gambling, counterfeit goods, malware.

## Additional Resources

### Reference Files

For detailed implementation guidance:
- **`references/window-openai-api.md`** - Complete `window.openai` API reference
- **`references/mcp-implementation.md`** - MCP server setup and tool patterns
- **`references/authentication.md`** - OAuth 2.1 implementation details

### External Documentation

- [Apps SDK Documentation](https://developers.openai.com/apps-sdk)
- [MCP Specification](https://modelcontextprotocol.io)
- [Apps SDK Reference](https://developers.openai.com/apps-sdk/reference)
