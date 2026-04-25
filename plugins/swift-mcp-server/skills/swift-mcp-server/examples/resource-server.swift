// Resource-Focused MCP Server
// Demonstrates resources, resource templates, subscriptions,
// binary content, and dynamic resource updates.
//
// Package.swift dependencies:
//   .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.11.0")
//   .product(name: "MCP", package: "swift-sdk")

import Foundation
import MCP

// Actor to manage mutable server state
actor AppState {
    private var config: [String: String] = [
        "theme": "dark",
        "language": "en",
        "debug": "false"
    ]
    private var subscriptions: Set<String> = []
    private var notes: [String: String] = [
        "welcome": "Welcome to the resource server!",
        "readme": "This server demonstrates MCP resources."
    ]

    func getConfig() -> [String: String] { config }

    func updateConfig(key: String, value: String) {
        config[key] = value
    }

    func getNote(id: String) -> String? { notes[id] }
    func listNoteIds() -> [String] { Array(notes.keys.sorted()) }

    func subscribe(to uri: String) { subscriptions.insert(uri) }
    func unsubscribe(from uri: String) { subscriptions.remove(uri) }
    func isSubscribed(to uri: String) -> Bool { subscriptions.contains(uri) }
}

@main
struct ResourceServer {
    static func main() async throws {
        let state = AppState()

        let server = Server(
            name: "resource-server",
            version: "1.0.0",
            capabilities: .init(
                resources: .init(subscribe: true, listChanged: true),
                tools: .init()
            )
        )

        // -- List Resources --
        await server.withMethodHandler(ListResources.self) { _ in
            let noteIds = await state.listNoteIds()
            var resources: [Resource] = [
                Resource(name: "App Config", uri: "config://app",
                         description: "Application configuration", mimeType: "application/json"),
                Resource(name: "Server Info", uri: "info://server",
                         description: "Server metadata", mimeType: "application/json"),
            ]
            for id in noteIds {
                resources.append(Resource(
                    name: "Note: \(id)", uri: "note://\(id)",
                    description: "Text note", mimeType: "text/plain"
                ))
            }
            return .init(resources: resources)
        }

        // -- Read Resources --
        await server.withMethodHandler(ReadResource.self) { params in
            switch params.uri {
            case "config://app":
                let config = await state.getConfig()
                let json = try JSONSerialization.data(
                    withJSONObject: config, options: [.prettyPrinted, .sortedKeys])
                let jsonString = String(data: json, encoding: .utf8) ?? "{}"
                return .init(contents: [.text(jsonString, uri: params.uri,
                                              mimeType: "application/json")])

            case "info://server":
                let info = """
                    {"name": "resource-server", "version": "1.0.0", "uptime": "running"}
                    """
                return .init(contents: [.text(info, uri: params.uri,
                                              mimeType: "application/json")])

            default:
                // Handle note:// URIs
                if params.uri.hasPrefix("note://") {
                    let id = String(params.uri.dropFirst("note://".count))
                    if let note = await state.getNote(id: id) {
                        return .init(contents: [.text(note, uri: params.uri,
                                                      mimeType: "text/plain")])
                    }
                }
                throw MCPError.invalidParams("Unknown resource: \(params.uri)")
            }
        }

        // -- Resource Templates --
        await server.withMethodHandler(ListResourceTemplates.self) { _ in
            .init(templates: [
                Resource.Template(
                    uriTemplate: "note://{noteId}",
                    name: "Note",
                    description: "Retrieve a note by ID",
                    mimeType: "text/plain"
                )
            ])
        }

        // -- Subscriptions --
        await server.withMethodHandler(ResourceSubscribe.self) { params in
            await state.subscribe(to: params.uri)
            return Empty()
        }

        await server.withMethodHandler(ResourceUnsubscribe.self) { params in
            await state.unsubscribe(from: params.uri)
            return Empty()
        }

        // -- Tool to update config (triggers resource update notification) --
        await server.withMethodHandler(ListTools.self) { _ in
            .init(tools: [
                Tool(
                    name: "set_config",
                    description: "Update a configuration value",
                    inputSchema: .object([
                        "type": "object",
                        "properties": .object([
                            "key": .object(["type": "string"]),
                            "value": .object(["type": "string"])
                        ]),
                        "required": .array(["key", "value"])
                    ])
                )
            ])
        }

        await server.withMethodHandler(CallTool.self) { [weak server] params in
            switch params.name {
            case "set_config":
                let key = params.arguments?["key"]?.stringValue ?? ""
                let value = params.arguments?["value"]?.stringValue ?? ""
                await state.updateConfig(key: key, value: value)

                // Notify subscribers that the config resource changed
                if await state.isSubscribed(to: "config://app") {
                    try await server?.notify(
                        ResourceUpdatedNotification.message(.init(uri: "config://app")))
                }

                return .init(content: [.text("Config updated: \(key) = \(value)")], isError: false)
            default:
                return .init(content: [.text("Unknown tool: \(params.name)")], isError: true)
            }
        }

        // Start server
        let transport = StdioTransport()
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }
}
