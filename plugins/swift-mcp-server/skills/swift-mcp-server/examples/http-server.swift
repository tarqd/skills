// HTTP MCP Server
// Demonstrates a stateful HTTP server with SSE streaming, session management,
// and request validation. Uses the SDK's built-in HTTPApp wrapper over SwiftNIO.
//
// Package.swift dependencies:
//   .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.11.0")
//   .product(name: "MCP", package: "swift-sdk")
//   // SwiftNIO is pulled in transitively by the SDK

import Foundation
import Logging
import MCP

// MARK: - Server Factory

/// Create a new server instance for each HTTP session.
func createSessionServer() async -> Server {
    let server = Server(
        name: "http-server",
        version: "1.0.0",
        capabilities: .init(
            logging: .init(),
            tools: .init(listChanged: true)
        )
    )

    await server.withMethodHandler(ListTools.self) { _ in
        .init(tools: [
            Tool(
                name: "echo",
                description: "Echo back the input",
                inputSchema: .object([
                    "type": "object",
                    "properties": .object([
                        "message": .object(["type": "string"])
                    ]),
                    "required": .array(["message"])
                ])
            ),
            Tool(
                name: "server_time",
                description: "Get the current server time",
                inputSchema: .object(["type": "object", "properties": .object([:])])
            )
        ])
    }

    await server.withMethodHandler(CallTool.self) { [weak server] params in
        switch params.name {
        case "echo":
            let message = params.arguments?["message"]?.stringValue ?? ""
            try await server?.log(level: .info, logger: "echo", data: .string("Echo: \(message)"))
            return .init(content: [.text(message)], isError: false)

        case "server_time":
            let formatter = ISO8601DateFormatter()
            let time = formatter.string(from: Date())
            return .init(content: [.text(time)], isError: false)

        default:
            return .init(content: [.text("Unknown tool: \(params.name)")], isError: true)
        }
    }

    await server.withMethodHandler(SetLoggingLevel.self) { _ in Empty() }

    return server
}

// MARK: - Main

@main
struct HTTPServer {
    static func main() async throws {
        var logger = Logger(label: "http-server",
                            factory: { StreamLogHandler.standardError(label: $0) })
        logger.logLevel = .info

        let port = 3001

        // Create HTTPApp with validation pipeline
        let app = HTTPApp(
            configuration: .init(
                host: "127.0.0.1",
                port: port,
                endpoint: "/mcp"
            ),
            validationPipeline: StandardValidationPipeline(validators: [
                // Validate request origin (CORS protection)
                OriginValidator.localhost(port: port),
                // Require SSE-compatible Accept header
                AcceptHeaderValidator(mode: .sseRequired),
                // Validate Content-Type for POST requests
                ContentTypeValidator(),
                // Check MCP protocol version
                ProtocolVersionValidator(),
                // Validate session IDs
                SessionValidator()
            ]),
            serverFactory: { sessionID in
                logger.info("New session: \(sessionID)")
                return await createSessionServer()
            },
            logger: logger
        )

        logger.info("Starting MCP HTTP server on http://127.0.0.1:\(port)/mcp")
        try await app.start()
    }
}
