# MCP Server Implementation Guide

Detailed guide for implementing MCP servers for ChatGPT apps.

## Server Architecture

ChatGPT apps use MCP (Model Context Protocol) for tool discovery and execution. The server handles:

1. **Tool Discovery** - Advertise tools with JSON Schema contracts
2. **Tool Execution** - Execute actions and return structured content
3. **Component Rendering** - Serve UI templates for widget rendering

## Transport Options

- **Streamable HTTP** - Recommended for production
- **Server-Sent Events (SSE)** - Alternative transport

## Tool Registration

### Basic Tool Definition

```ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

const server = new McpServer({
  name: "my-app",
  version: "1.0.0"
});

server.registerTool(
  "get-tasks",
  {
    title: "Get Tasks",
    description: "Retrieves tasks from the workspace",
    inputSchema: {
      type: "object",
      properties: {
        workspace: { type: "string", description: "Workspace ID" },
        status: { type: "string", enum: ["todo", "done", "all"] }
      },
      required: ["workspace"]
    },
    annotations: {
      readOnlyHint: true,
      destructiveHint: false,
      openWorldHint: false
    }
  },
  async ({ workspace, status }) => {
    const tasks = await db.getTasks(workspace, status);
    return {
      structuredContent: { tasks: tasks.slice(0, 10) },
      content: [{ type: "text", text: `Found ${tasks.length} tasks` }]
    };
  }
);
```

### Tool with UI Template

```ts
server.registerTool(
  "show-kanban",
  {
    title: "Show Kanban Board",
    description: "Display interactive kanban board",
    inputSchema: {
      type: "object",
      properties: {
        workspace: { type: "string" }
      },
      required: ["workspace"]
    },
    _meta: {
      "openai/outputTemplate": "ui://widget/kanban.html",
      "openai/toolInvocation/invoking": "Loading board...",
      "openai/toolInvocation/invoked": "Board ready"
    },
    annotations: {
      readOnlyHint: true,
      destructiveHint: false,
      openWorldHint: false
    }
  },
  async ({ workspace }) => {
    const board = await loadBoard(workspace);
    return {
      structuredContent: {
        columns: board.columns.map(c => ({
          id: c.id,
          title: c.title,
          taskCount: c.tasks.length
        }))
      },
      content: [{ type: "text", text: "Drag cards to update status" }],
      _meta: {
        tasksById: Object.fromEntries(board.tasks.map(t => [t.id, t])),
        lastSync: new Date().toISOString()
      }
    };
  }
);
```

## Tool Metadata Fields

### `_meta` at Tool Descriptor Level

| Field | Type | Purpose |
|-------|------|---------|
| `openai/outputTemplate` | string (URI) | Component HTML template resource |
| `openai/widgetAccessible` | boolean | Enable widget→tool calls (default: false) |
| `openai/visibility` | "public" \| "private" | Hide from model, keep callable by widget |
| `openai/toolInvocation/invoking` | string (≤64 chars) | Status text while running |
| `openai/toolInvocation/invoked` | string (≤64 chars) | Status text after completion |
| `openai/fileParams` | string[] | Input fields representing file uploads |
| `securitySchemes` | array | Authentication requirements |

### Tool Annotations

Required for ChatGPT's safety system:

| Annotation | Type | Purpose |
|------------|------|---------|
| `readOnlyHint` | boolean | **Required.** Tool only reads data |
| `destructiveHint` | boolean | **Required.** Tool may delete/overwrite data |
| `openWorldHint` | boolean | **Required.** Tool publishes externally |
| `idempotentHint` | boolean | Optional. Repeated calls have no additional effect |

Annotations influence how ChatGPT frames tool calls but servers must enforce actual authorization.

## Component Template Registration

Register UI templates as resources with `text/html+skybridge` MIME type:

```ts
server.registerResource(
  "kanban-widget",
  "ui://widget/kanban.html",
  {},
  async () => ({
    contents: [{
      uri: "ui://widget/kanban.html",
      mimeType: "text/html+skybridge",
      text: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>
  <div id="root"></div>
  <script type="module" src="https://cdn.example.com/widget.js"></script>
</body>
</html>
      `,
      _meta: {
        "openai/widgetDescription": "Interactive kanban board for task management",
        "openai/widgetPrefersBorder": true,
        "openai/widgetDomain": "https://myapp.example.com",
        "openai/widgetCSP": {
          connect_domains: ["https://api.example.com"],
          resource_domains: ["https://*.oaistatic.com", "https://cdn.example.com"],
          redirect_domains: ["https://checkout.example.com"],
          frame_domains: []
        }
      }
    }]
  })
);
```

### Component Resource `_meta` Fields

| Field | Type | Purpose |
|-------|------|---------|
| `openai/widgetDescription` | string | Model-visible summary (reduces narration) |
| `openai/widgetPrefersBorder` | boolean | Hint for bordered card rendering |
| `openai/widgetDomain` | string (origin) | Dedicated origin for hosted components |
| `openai/widgetCSP` | object | Content Security Policy allowlists |

### CSP Configuration

```ts
"openai/widgetCSP": {
  // Required: domains for fetch/XHR
  connect_domains: ["https://api.example.com"],

  // Required: domains for static assets (images, fonts, scripts)
  resource_domains: ["https://cdn.example.com"],

  // Optional: iframe sources (triggers stricter review)
  frame_domains: ["https://embed.example.com"],

  // Optional: openExternal redirect targets
  redirect_domains: ["https://checkout.example.com"]
}
```

## Tool Response Structure

### Three Response Payloads

```ts
return {
  // Model + widget visible. Must match outputSchema if defined.
  // Keep concise - model reads verbatim.
  structuredContent: {
    tasks: tasks.slice(0, 5),
    totalCount: tasks.length
  },

  // Model + widget visible. Optional narration text.
  content: [
    { type: "text", text: "Found 42 tasks. Showing top 5." }
  ],

  // Widget-only. Hidden from model.
  // Use for large data, sensitive info, or UI-specific details.
  _meta: {
    allTasks: tasks,
    userPermissions: permissions,
    debugInfo: { queryTime: 45 }
  }
};
```

### Host-Provided `_meta` in Responses

These fields are added by ChatGPT, not your server:

| Field | Purpose |
|-------|---------|
| `openai/widgetSessionId` | Stable ID for mounted widget instance (for logging) |
| `mcp/www_authenticate` | RFC 7235 OAuth challenge triggers |

## Client-Supplied Request Metadata

ChatGPT sends context in request `_meta`:

| Field | When | Type | Purpose |
|-------|------|------|---------|
| `openai/locale` | Always | BCP 47 string | User's requested locale |
| `openai/userAgent` | Tool calls | string | Analytics hint |
| `openai/userLocation` | Tool calls | object | Coarse location (city, region, country, timezone) |
| `openai/subject` | Tool calls | string | Anonymized user ID for rate limiting |
| `openai/session` | Tool calls | string | Anonymized conversation ID |

**Important:** Never rely on `userAgent` or `userLocation` for authorization. Servers must tolerate their absence.

## Widget-Callable Tools

Enable tools to be called from widgets:

```ts
server.registerTool(
  "update-task",
  {
    title: "Update Task",
    inputSchema: { /* ... */ },
    _meta: {
      "openai/widgetAccessible": true,  // Allow widget calls
      "openai/visibility": "private"     // Hide from model (optional)
    },
    annotations: {
      readOnlyHint: false,
      destructiveHint: false,
      openWorldHint: false
    }
  },
  async (params) => { /* ... */ }
);
```

## File Parameter Handling

Accept file uploads in tools:

```ts
server.registerTool(
  "process-image",
  {
    title: "Process Image",
    inputSchema: {
      type: "object",
      properties: {
        imageToProcess: { type: "string", description: "File ID of uploaded image" },
        operation: { type: "string", enum: ["resize", "crop", "filter"] }
      },
      required: ["imageToProcess", "operation"]
    },
    _meta: {
      "openai/fileParams": ["imageToProcess"]  // Mark as file parameter
    }
  },
  async ({ imageToProcess, operation }) => {
    // imageToProcess is a file ID that can be used to fetch the file
    const result = await processImage(imageToProcess, operation);
    return { structuredContent: result };
  }
);
```

## Error Handling

Return errors with appropriate structure:

```ts
// Authentication error - triggers OAuth flow
return {
  content: [{ type: "text", text: "Authentication required" }],
  _meta: {
    "mcp/www_authenticate": "Bearer realm=\"example\", error=\"invalid_token\""
  }
};

// Application error
return {
  content: [{ type: "text", text: "Task not found" }],
  structuredContent: { error: "NOT_FOUND", taskId: params.taskId }
};
```

## Company Knowledge Integration

For Business/Enterprise/Edu integration with Company Knowledge:

1. Use standard `search` and `fetch` tool signatures
2. Mark tools with `readOnlyHint: true`
3. Return canonical URLs in responses for citations

```ts
server.registerTool(
  "search",
  {
    title: "Search Documents",
    inputSchema: {
      type: "object",
      properties: {
        query: { type: "string" }
      },
      required: ["query"]
    },
    annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
  },
  async ({ query }) => {
    const results = await searchDocs(query);
    return {
      structuredContent: {
        results: results.map(r => ({
          title: r.title,
          url: r.canonicalUrl,  // For citations
          snippet: r.snippet
        }))
      }
    };
  }
);
```

## Memory Considerations

- Models decide memory usage (user-controlled)
- Keep tool inputs explicit and required
- Treat memory context as hints, not authoritative
- Provide safe defaults for missing context
- Don't assume prior conversation context is available
