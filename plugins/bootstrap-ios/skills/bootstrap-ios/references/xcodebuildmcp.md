# XcodeBuildMCP

Use XcodeBuildMCP when an agent needs reliable Xcode project discovery, build,
test, simulator, logging, or debug workflows.

Primary repo:

- https://github.com/getsentry/XcodeBuildMCP
- Docs: https://xcodebuildmcp.com/docs
- Client setup: https://xcodebuildmcp.com/docs/clients
- Skills setup: https://xcodebuildmcp.com/docs/skills

## Install options

Homebrew:

```bash
brew tap getsentry/xcodebuildmcp
brew install xcodebuildmcp
```

npm:

```bash
npm install -g xcodebuildmcp@latest
```

Verify:

```bash
xcodebuildmcp --help
```

## Client setup

Most MCP clients can launch the server on demand:

```bash
npx -y xcodebuildmcp@latest mcp
```

For client-specific JSON snippets, read:

- https://xcodebuildmcp.com/docs/clients

## Agent skills

XcodeBuildMCP includes optional agent skills. If the user asks to initialize
them:

```bash
xcodebuildmcp init
```

or:

```bash
npx -y xcodebuildmcp@latest init
```

## CLI usage

Examples from the project docs:

```bash
xcodebuildmcp tools
xcodebuildmcp simulator build --scheme MyApp --project-path ./MyApp.xcodeproj
xcodebuildmcp upgrade --check
```

Prefer tool/CLI output that is small and parseable. If raw `xcodebuild` is the
only available route, pipe it through `xcbeautify` when available and keep the
failure excerpt concise.

## Requirements to check

- macOS 14.5+
- Xcode 16+
- Node.js 18+ for npm/npx mode
- code signing configured for device tools

## Reporting

When using XcodeBuildMCP, report:

- whether the MCP server or CLI was used
- project/workspace path
- scheme
- simulator/device
- build/test command or MCP tool
- exact blocker if signing, simulator, Xcode, or Node is missing
