# {{ plugin_title }}

{{ plugin_description }}

## Installation

Add this plugin to your Claude Code configuration:

```bash
claude plugins add /path/to/{{ plugin_name }}
```

Or add to a marketplace's `marketplace.json`.

## Structure

```
{{ plugin_name }}/
├── .claude-plugin/
│   └── plugin.json
├── skills/       # Add skills with: just add-skill {{ plugin_name }}
├── commands/     # Add commands manually
├── agents/       # Add agents with: just add-agent {{ plugin_name }}
└── hooks/        # Add hooks with: just add-hook {{ plugin_name }}
```

## License

{{ license }}
