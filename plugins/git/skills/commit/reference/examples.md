# Commit Organization Examples

This file contains detailed examples of how to organize commits following the commit skill workflow.

## Example 1: User Requests Revision

**User**: "Commit my changes"

**After analysis, propose:**

```
Proposed commits:

1. chore(deps): Update axios to 1.6.0
   - package.json
   - package-lock.json

   Body: Addresses CVE-2023-xxxx security vulnerability in axios.
   Previous version allowed potential header injection attacks.

2. refactor(api): Extract auth logic to middleware
   - src/middleware/auth.js
   - src/routes/users.js
   - src/routes/posts.js

   Body: Authentication logic was duplicated across route handlers,
   making it difficult to maintain consistent auth behavior. This
   extracts the logic into reusable middleware, reducing duplication
   and making future auth changes easier to implement consistently.

3. feat(users): Add email verification endpoint
   - src/routes/users.js
   - src/services/email.js
   - src/templates/verify-email.html

   Body: Implements POST /users/verify endpoint to verify user email
   addresses via token sent during registration. This reduces spam
   accounts and ensures we can reliably contact users.

4. test(users): Add tests for email verification
   - tests/users.test.js

   Body: Covers success case, invalid token, and expired token
   scenarios to ensure verification flow works correctly and fails
   safely for edge cases.

Proceed with these commits? (yes/no/revise)
```

**User**: "revise - combine commits 2 and 3"

**Propose revised plan:**

```
Revised commits:

1. chore(deps): Update axios to 1.6.0
   - package.json
   - package-lock.json

   Body: Addresses CVE-2023-xxxx security vulnerability in axios.
   Previous version allowed potential header injection attacks.

2. feat(users): Add email verification with auth middleware
   - src/middleware/auth.js
   - src/routes/users.js
   - src/routes/posts.js
   - src/services/email.js
   - src/templates/verify-email.html

   Body: Extracts authentication logic to reusable middleware and
   implements email verification endpoint. While these are separate
   concerns, they were developed together as the verification endpoint
   required the new auth middleware pattern to function correctly.

3. test(users): Add tests for email verification
   - tests/users.test.js

   Body: Covers success case, invalid token, and expired token
   scenarios to ensure verification flow works correctly and fails
   safely for edge cases.

Proceed with these commits? (yes/no/revise)
```

---

## Example 2: Detecting Secrets

**User**: "Commit all my changes"

**After analysis:**

```
⚠️  Warning: Found files that may contain secrets:
- .env (environment variables)
- config/credentials.json (credentials)

These files will be excluded from commits. Consider adding them to .gitignore.

Proposed commits:

1. feat(auth): Add OAuth integration
   - src/auth/oauth.js
   - src/config/oauth-config.js

   Body: Adds support for Google and GitHub OAuth providers to allow
   users to sign in with existing accounts. This improves conversion
   rates by removing registration friction and provides better security
   through delegated authentication.

   Configuration is read from environment variables to keep secrets out
   of the codebase.

Proceed with these commits? (yes/no/revise)
```

---

## Example 3: Single Coherent Change

**User**: "Commit the bug fix"

**After analysis (all changes are related):**

```
Proposed commits:

1. fix(auth): Prevent token expiry race condition
   - src/middleware/auth.js
   - src/services/token.js
   - tests/auth.test.js

   Body: Users were experiencing intermittent 401 errors when their
   tokens were close to expiring. The issue occurred when multiple
   concurrent requests all detected an expired token and attempted to
   refresh it simultaneously, causing some requests to fail.

   This adds a mutex lock to ensure only one token refresh happens at
   a time. Other requests wait for the refresh to complete and then
   use the new token. Tests verify that concurrent requests correctly
   share the refreshed token.

   Fixes: #789

Proceed with these commits? (yes/no)
```

---

## Example 4: Pre-commit Hook Failure

**User**: "yes"

**During execution:**

```
Executing commit 1...
❌ Pre-commit hook failed: ESLint errors found

Fixing ESLint errors...
✓ Fixed 3 linting issues in src/auth/oauth.js

Re-staging files and committing...
✓ Commit 1 created successfully

All commits completed successfully!
```

---

## Example 5: Multiple Logical Changes

**User**: "Commit my changes"

**After analysis, propose:**

```
Proposed commits:

1. chore(deps): Update React to 18.2.0
   - package.json
   - package-lock.json

   Body: Updates React to latest stable version for improved
   performance and access to new concurrent rendering features.

2. refactor(components): Migrate class components to hooks
   - src/components/UserProfile.jsx
   - src/components/Dashboard.jsx
   - src/components/Settings.jsx

   Body: Converts legacy class components to functional components
   with hooks for better code reusability and easier testing. This
   preparation step enables future concurrent rendering optimizations.

3. feat(dashboard): Add real-time data updates
   - src/components/Dashboard.jsx
   - src/hooks/useWebSocket.js
   - src/services/websocket.js

   Body: Implements WebSocket connection to stream real-time updates
   to the dashboard. Users now see live data without manual refresh,
   improving monitoring capabilities and user experience.

4. test(dashboard): Add WebSocket integration tests
   - tests/components/Dashboard.test.jsx
   - tests/hooks/useWebSocket.test.js

   Body: Verifies WebSocket connection lifecycle, message handling,
   reconnection logic, and error scenarios to ensure reliable
   real-time updates.

5. docs: Update README with WebSocket configuration
   - README.md

   Body: Documents new WEBSOCKET_URL environment variable and
   connection requirements for running the application with real-time
   features.

Proceed with these commits? (yes/no/revise)
```
