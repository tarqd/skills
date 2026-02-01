# Authentication for ChatGPT Apps

Complete guide to implementing OAuth 2.1 authentication for ChatGPT apps.

## When Authentication is Required

- **Anonymous (no auth):** Read-only public data, no user-specific content
- **OAuth 2.1 required:** Any user data access, write operations, personalized content

## OAuth 2.1 Architecture

Three components work together:

1. **Resource Server** - Your MCP server that verifies access tokens
2. **Authorization Server** - Identity provider issuing tokens (Auth0, Okta, Cognito, custom)
3. **Client** - ChatGPT acting on user's behalf with dynamic registration and PKCE

## Required Endpoints

### Protected Resource Metadata

Host at `/.well-known/oauth-protected-resource`:

```json
{
  "resource": "https://api.example.com",
  "authorization_servers": ["https://auth.example.com"],
  "scopes_supported": ["read", "write", "admin"],
  "bearer_methods_supported": ["header"],
  "resource_documentation": "https://docs.example.com/api"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `resource` | Yes | Canonical HTTPS identifier for your server |
| `authorization_servers` | Yes | Issuer base URLs |
| `scopes_supported` | Yes | Available permission scopes |
| `bearer_methods_supported` | No | Token transmission methods |
| `resource_documentation` | No | Link to API documentation |

### Authorization Server Requirements

The identity provider must expose standard OAuth 2.1 discovery documents and support:

- **Discovery endpoint:** `/.well-known/oauth-authorization-server` or `/.well-known/openid-configuration`
- **Dynamic client registration (DCR)**
- **PKCE with S256 code challenge method**
- **Authorization code grant type**

Minimum discovery document fields:

```json
{
  "issuer": "https://auth.example.com",
  "authorization_endpoint": "https://auth.example.com/authorize",
  "token_endpoint": "https://auth.example.com/token",
  "registration_endpoint": "https://auth.example.com/register",
  "code_challenge_methods_supported": ["S256"],
  "grant_types_supported": ["authorization_code"],
  "response_types_supported": ["code"]
}
```

## OAuth Flow Sequence

1. **Metadata Discovery:** ChatGPT queries `/.well-known/oauth-protected-resource`
2. **Client Registration:** ChatGPT performs DCR, obtaining `client_id`
3. **Authorization:** User initiates auth code + PKCE flow, authenticates, grants consent
4. **Token Exchange:** ChatGPT exchanges authorization code for access token
5. **API Requests:** ChatGPT includes token in requests; server validates each call

## Security Scheme Declaration

Declare authentication requirements on tools:

### No Authentication

```ts
server.registerTool("public-search", {
  title: "Public Search",
  inputSchema: { /* ... */ },
  _meta: {
    securitySchemes: [{ type: "noauth" }]
  }
});
```

### OAuth Required

```ts
server.registerTool("get-user-data", {
  title: "Get User Data",
  inputSchema: { /* ... */ },
  _meta: {
    securitySchemes: [{
      type: "oauth2",
      scopes: ["read", "profile"]
    }]
  }
});
```

### Optional Authentication

Combine schemes for optional auth (anonymous fallback):

```ts
server.registerTool("get-recommendations", {
  title: "Get Recommendations",
  inputSchema: { /* ... */ },
  _meta: {
    securitySchemes: [
      { type: "noauth" },                          // Anonymous fallback
      { type: "oauth2", scopes: ["read"] }  // Personalized if authenticated
    ]
  }
});
```

## Token Verification

Your MCP server must verify every authenticated request:

```ts
import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';

const client = jwksClient({
  jwksUri: 'https://auth.example.com/.well-known/jwks.json',
  cache: true,
  rateLimit: true
});

async function verifyToken(token: string): Promise<TokenPayload> {
  const decoded = jwt.decode(token, { complete: true });
  if (!decoded) throw new Error('Invalid token format');

  const key = await client.getSigningKey(decoded.header.kid);
  const publicKey = key.getPublicKey();

  const payload = jwt.verify(token, publicKey, {
    issuer: 'https://auth.example.com',
    audience: 'https://api.example.com',
    algorithms: ['RS256']
  }) as TokenPayload;

  return payload;
}
```

### Verification Checklist

| Check | Description |
|-------|-------------|
| Signature | Validate using JWKS public keys |
| Issuer (`iss`) | Must match expected authorization server |
| Audience (`aud`) | Must include your resource server identifier |
| Expiration (`exp`) | Token must not be expired |
| Not Before (`nbf`) | Token must be valid for current time |
| Scopes | Token must include required scopes for operation |

### Error Response

On verification failure, return 401 with WWW-Authenticate header:

```ts
// In your MCP server handler
if (!isValidToken) {
  return {
    content: [{ type: "text", text: "Authentication required" }],
    _meta: {
      "mcp/www_authenticate": `Bearer realm="example", error="invalid_token", error_description="Token expired"`
    }
  };
}
```

## Triggering OAuth UI

ChatGPT displays authentication UI when these conditions exist:

1. Published resource metadata at well-known endpoint
2. Tool-level `securitySchemes` declarations
3. Runtime 401 error with `_meta["mcp/www_authenticate"]`

Example trigger flow:

```ts
async function handleToolCall(token: string | undefined, params: any) {
  // No token provided
  if (!token) {
    return {
      content: [{ type: "text", text: "Please sign in to continue" }],
      _meta: {
        "mcp/www_authenticate": "Bearer realm=\"example\""
      }
    };
  }

  try {
    const payload = await verifyToken(token);
    // Continue with authorized operation...
  } catch (error) {
    return {
      content: [{ type: "text", text: "Session expired, please sign in again" }],
      _meta: {
        "mcp/www_authenticate": `Bearer realm="example", error="invalid_token"`
      }
    };
  }
}
```

## Client Identification

### Current Limitations

- Network-level filtering (IP allowlisting) is the only reliable way to confirm ChatGPT origin
- Dynamic client registration creates per-session clients, causing scale challenges
- `client_id` values are ephemeral and shouldn't be used for authorization

### Future: Client Metadata Documents (CMID)

OpenAI plans to provide signed identity verification through CMID, enabling cryptographic verification of ChatGPT as the client.

## Recommended Identity Providers

Providers that support all requirements:

| Provider | DCR | PKCE | Resource Parameter |
|----------|-----|------|-------------------|
| Auth0 | Yes | Yes | Yes |
| Okta | Yes | Yes | Yes |
| Stytch | Yes | Yes | Yes |
| AWS Cognito | Yes | Yes | Partial |
| Custom | Implement | Implement | Implement |

## Implementation Checklist

### Server Setup

- [ ] Host `/.well-known/oauth-protected-resource` metadata
- [ ] Configure authorization server with DCR support
- [ ] Enable PKCE with S256 support
- [ ] Implement token verification middleware
- [ ] Return proper 401 responses with WWW-Authenticate

### Tool Configuration

- [ ] Add `securitySchemes` to tool `_meta`
- [ ] Declare required scopes per tool
- [ ] Handle unauthenticated requests gracefully
- [ ] Never expose sensitive data without auth

### Testing

- [ ] Test anonymous tool access
- [ ] Test OAuth flow end-to-end
- [ ] Test token expiration handling
- [ ] Test scope validation
- [ ] Use MCP Inspector for OAuth debugging

## Security Best Practices

1. **Never trust client hints for authorization** - `userAgent`, `userLocation` are for analytics only
2. **Validate on every request** - Don't cache authorization decisions
3. **Use short-lived tokens** - Implement refresh token rotation
4. **Scope minimization** - Request only needed scopes
5. **Audit logging** - Log authentication events for security monitoring
6. **Rate limiting** - Use `openai/subject` for per-user rate limits

## Development Workflow

1. **Start with dev tenant** - Use test identity provider instance
2. **Short-lived tokens** - Easy iteration during development
3. **Gate access** - Limit to trusted testers initially
4. **Use ngrok** - HTTPS required for OAuth redirects
5. **MCP Inspector** - Debug OAuth flows locally

```bash
# Start local server
npm run dev

# Expose via HTTPS
ngrok http 3000

# Test in MCP Inspector
open http://localhost:3000/mcp
```
