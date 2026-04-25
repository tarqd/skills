// Tool-Focused MCP Server
// Demonstrates multiple tools with different input schemas, annotations,
// structured content, progress reporting, and logging.
//
// Package.swift dependencies:
//   .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.11.0")
//   .product(name: "MCP", package: "swift-sdk")

import Foundation
import Logging
import MCP

@main
struct ToolServer {
    static func main() async throws {
        var logger = Logger(label: "tool-server",
                            factory: { StreamLogHandler.standardError(label: $0) })
        logger.logLevel = .info

        let server = Server(
            name: "tool-server",
            version: "1.0.0",
            capabilities: .init(
                logging: .init(),
                tools: .init(listChanged: true)
            )
        )

        // -- List Tools --
        await server.withMethodHandler(ListTools.self) { _ in
            .init(tools: [
                // Read-only tool with simple input
                Tool(
                    name: "get_weather",
                    description: "Get current weather for a location",
                    inputSchema: .object([
                        "type": "object",
                        "properties": .object([
                            "city": .object(["type": "string", "description": "City name"]),
                            "units": .object([
                                "type": "string",
                                "enum": .array(["metric", "imperial"]),
                                "default": "metric"
                            ])
                        ]),
                        "required": .array(["city"])
                    ]),
                    annotations: .init(readOnlyHint: true, openWorldHint: true)
                ),

                // Computation tool with structured output
                Tool(
                    name: "calculate",
                    description: "Evaluate a math expression",
                    inputSchema: .object([
                        "type": "object",
                        "properties": .object([
                            "expression": .object(["type": "string", "description": "Math expression"]),
                            "precision": .object(["type": "integer", "default": .int(2)])
                        ]),
                        "required": .array(["expression"])
                    ]),
                    outputSchema: .object([
                        "type": "object",
                        "properties": .object([
                            "result": .object(["type": "number"]),
                            "expression": .object(["type": "string"])
                        ])
                    ]),
                    annotations: .init(idempotentHint: true, readOnlyHint: true)
                ),

                // Long-running tool with progress
                Tool(
                    name: "analyze_data",
                    description: "Analyze a dataset (supports progress reporting)",
                    inputSchema: .object([
                        "type": "object",
                        "properties": .object([
                            "dataset": .object(["type": "string", "description": "Dataset identifier"]),
                            "depth": .object([
                                "type": "string",
                                "enum": .array(["quick", "standard", "deep"]),
                                "default": "standard"
                            ])
                        ]),
                        "required": .array(["dataset"])
                    ]),
                    annotations: .init(readOnlyHint: true)
                ),

                // Destructive tool
                Tool(
                    name: "delete_record",
                    description: "Delete a record by ID",
                    inputSchema: .object([
                        "type": "object",
                        "properties": .object([
                            "id": .object(["type": "string", "description": "Record ID"]),
                            "confirm": .object(["type": "boolean", "description": "Confirm deletion"])
                        ]),
                        "required": .array(["id", "confirm"])
                    ]),
                    annotations: .init(destructiveHint: true, idempotentHint: true)
                )
            ])
        }

        // -- Handle Tool Calls --
        await server.withMethodHandler(CallTool.self) { [weak server] params in
            switch params.name {
            case "get_weather":
                let city = params.arguments?["city"]?.stringValue ?? "Unknown"
                let units = params.arguments?["units"]?.stringValue ?? "metric"

                try await server?.log(level: .info, logger: "weather",
                                      data: .string("Fetching weather for \(city)"))

                // Simulated weather response
                let temp = units == "metric" ? "22°C" : "72°F"
                return .init(content: [.text("Weather in \(city): Sunny, \(temp)")], isError: false)

            case "calculate":
                let expr = params.arguments?["expression"]?.stringValue ?? ""
                // Simulated calculation
                let result = 42.0
                return try .init(
                    content: [.text("\(expr) = \(result)")],
                    structuredContent: .object([
                        "result": .double(result),
                        "expression": .string(expr)
                    ]),
                    isError: false
                )

            case "analyze_data":
                let dataset = params.arguments?["dataset"]?.stringValue ?? ""
                let depth = params.arguments?["depth"]?.stringValue ?? "standard"
                let steps = depth == "quick" ? 3 : depth == "deep" ? 10 : 5

                // Report progress if client supports it
                if let token = params._meta?.progressToken {
                    for step in 0...steps {
                        let progress = Double(step) / Double(steps) * 100
                        try await server?.notify(ProgressNotification.message(
                            .init(progressToken: token, progress: progress, total: 100,
                                  message: "Step \(step)/\(steps)")
                        ))
                        try await Task.sleep(for: .milliseconds(200))
                    }
                }

                return .init(
                    content: [.text("Analysis of '\(dataset)' complete (\(depth) mode)")],
                    isError: false
                )

            case "delete_record":
                let id = params.arguments?["id"]?.stringValue ?? ""
                let confirm = params.arguments?["confirm"]?.boolValue ?? false
                guard confirm else {
                    return .init(content: [.text("Deletion not confirmed. Set confirm=true.")], isError: true)
                }
                try await server?.log(level: .warning, logger: "data",
                                      data: .string("Deleted record: \(id)"))
                return .init(content: [.text("Record \(id) deleted")], isError: false)

            default:
                return .init(content: [.text("Unknown tool: \(params.name)")], isError: true)
            }
        }

        // -- Handle Logging Level --
        await server.withMethodHandler(SetLoggingLevel.self) { params in
            logger.info("Client set log level to \(params.level)")
            return Empty()
        }

        // Start server
        let transport = StdioTransport(logger: logger)
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }
}
