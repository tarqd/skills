# window.openai API Reference

Complete reference for the `window.openai` bridge API available to ChatGPT app widgets.

## State & Data Properties

### toolInput

Arguments supplied when the tool was invoked.

```ts
const { workspace, filter } = window.openai.toolInput;
```

### toolOutput

The `structuredContent` returned by the MCP server. Keep fields concise - the model reads them verbatim.

```ts
const tasks = window.openai.toolOutput?.tasks ?? [];
```

### toolResponseMetadata

The `_meta` payload from the tool response. Only the widget sees this - never reaches the model.

```ts
const fullTaskData = window.openai.toolResponseMetadata?.tasksById;
```

### widgetState

Snapshot of UI state persisted between renders. Scoped to individual widget instances.

```ts
const selectedId = window.openai.widgetState?.selectedTask;
```

## Methods

### setWidgetState(state)

Stores a new state snapshot synchronously. Call after every meaningful UI interaction.

```ts
window.openai.setWidgetState({
  selectedTask: taskId,
  expandedPanels: ['details', 'comments']
});
```

**Important:** Anything passed to `setWidgetState` is visible to the model. Keep payloads focused and under 4k tokens.

### callTool(name, args)

Invoke another MCP tool from the widget. Requires tool to have `openai/widgetAccessible: true`.

```ts
const result = await window.openai.callTool('update-task', {
  taskId: '123',
  status: 'done'
});
```

### sendFollowUpMessage({ prompt })

Ask ChatGPT to post a message authored by the component.

```ts
await window.openai.sendFollowUpMessage({
  prompt: 'Show me the tasks due this week'
});
```

### uploadFile(file)

Upload a user-selected file and receive a `fileId`. Supported formats: PNG, JPEG, WebP.

```ts
const input = document.querySelector('input[type="file"]');
const file = input.files[0];
const { fileId } = await window.openai.uploadFile(file);
```

### getFileDownloadUrl({ fileId })

Retrieve a temporary download URL for a previously uploaded file.

```ts
const { url } = await window.openai.getFileDownloadUrl({ fileId });
const img = document.createElement('img');
img.src = url;
```

### requestDisplayMode(mode)

Request alternate presentation modes:

```ts
// Available modes: 'inline', 'pip', 'fullscreen'
await window.openai.requestDisplayMode('fullscreen');
```

- **inline** - Default conversation view
- **pip** - Picture-in-picture sidebar view
- **fullscreen** - Maximum screen space

Note: Mobile devices may coerce 'pip' to 'fullscreen'.

### requestModal({ params, template })

Spawn a modal dialog owned by ChatGPT with an alternate UI template.

```ts
await window.openai.requestModal({
  template: 'ui://widget/settings-modal.html',
  params: { userId: '123' }
});
```

### notifyIntrinsicHeight(height)

Report dynamic widget heights to avoid scroll clipping.

```ts
const contentHeight = document.body.scrollHeight;
window.openai.notifyIntrinsicHeight(contentHeight);
```

### openExternal({ href })

Open a vetted external link in the user's browser. URL must be in `redirect_domains` CSP.

```ts
await window.openai.openExternal({
  href: 'https://checkout.example.com/order/123'
});
```

### setOpenInAppUrl({ href })

Set the destination URL for the "Open in App" button in fullscreen mode.

```ts
window.openai.setOpenInAppUrl({
  href: 'https://app.example.com/board/456'
});
```

## Context Properties

These are readable signals for adapting widget appearance and behavior:

### theme

Current visual theme signal. Subscribe to react to theme changes.

```ts
const currentTheme = window.openai.theme; // 'light' | 'dark'
```

### displayMode

Current display context.

```ts
const mode = window.openai.displayMode; // 'inline' | 'pip' | 'fullscreen'
```

### maxHeight

Maximum widget height in pixels.

```ts
const maxH = window.openai.maxHeight;
```

### safeArea

Safe rendering area accounting for system UI.

```ts
const { top, bottom, left, right } = window.openai.safeArea;
```

### view

View context information.

### userAgent

User agent hint for analytics and formatting.

```ts
const ua = window.openai.userAgent;
```

### locale

User's locale in BCP 47 format.

```ts
const locale = window.openai.locale; // e.g., 'en-US', 'ja-JP'
```

## React Hooks Pattern

Wrap `window.openai` access with React hooks using `useSyncExternalStore`:

```tsx
function useToolOutput<T>(): T | undefined {
  return useSyncExternalStore(
    () => () => {},
    () => window.openai?.toolOutput as T
  );
}

function useWidgetState<T>(initialState: () => T) {
  const [state, setState] = useState<T>(() =>
    window.openai?.widgetState ?? initialState()
  );

  const setWidgetState = useCallback((newState: T | ((prev: T) => T)) => {
    setState(prev => {
      const next = typeof newState === 'function'
        ? (newState as (prev: T) => T)(prev)
        : newState;
      window.openai?.setWidgetState(next);
      return next;
    });
  }, []);

  return [state, setWidgetState] as const;
}
```

Usage:

```tsx
function TaskList() {
  const tasks = useToolOutput<{ tasks: Task[] }>()?.tasks ?? [];
  const [state, setState] = useWidgetState(() => ({ selected: null }));

  return tasks.map(task => (
    <button
      key={task.id}
      onClick={() => setState(s => ({ ...s, selected: task.id }))}
    >
      {task.title}
    </button>
  ));
}
```

## File Handling Pattern

For widgets that handle file uploads with model visibility:

```ts
interface WidgetState {
  modelContent: { description: string };
  privateContent: { largeData: object };
  imageIds: string[];
}

async function handleFileUpload(file: File) {
  const { fileId } = await window.openai.uploadFile(file);

  const currentState = window.openai.widgetState as WidgetState;
  window.openai.setWidgetState({
    ...currentState,
    imageIds: [...currentState.imageIds, fileId]
  });
}
```

This structure enables the model to access image IDs in follow-up conversation turns.
