// Minimal MCP Server in Swift
// A bare-minimum server with a single tool, communicating over stdio.
//
// Package.swift dependencies:
//   .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.11.0")
//   .product(name: "MCP", package: "swift-sdk")

import MCP

@main
struct MinimalServer {
    static func main() async throws {
        let server = Server(
            name: "minimal-server",
            version: "1.0.0",
            capabilities: .init(
                tools: .init()
            )
        )

        // List available tools
        await server.withMethodHandler(ListTools.self) { _ in
            .init(tools: [
                Tool(
                    name: "hello",
                    description: "Returns a greeting",
                    inputSchema: .object([
                        "type": "object",
                        "properties": .object([
                            "name": .object([
                                "type": "string",
                                "description": "Name to greet"
                            ])
                        ])
                    ])
                )
            ])
        }

        // Handle tool calls
        await server.withMethodHandler(CallTool.self) { params in
            switch params.name {
            case "hello":
                let name = params.arguments?["name"]?.stringValue ?? "World"
                return .init(content: [.text("Hello, \(name)!")], isError: false)
            default:
                return .init(content: [.text("Unknown tool: \(params.name)")], isError: true)
            }
        }

        // Start with stdio transport
        let transport = StdioTransport()
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }
}
