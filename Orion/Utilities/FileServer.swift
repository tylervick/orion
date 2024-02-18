//
//  FileServer.swift
//  Orion
//
//  Created by Tyler Vick on 2/17/24.
//

import FlyingFox
import FlyingSocks
import Foundation

final class FileServer {
    private let server: HTTPServer

    init(addr: SocketAddress) {
        server = HTTPServer(address: addr)
    }

    func start(root: URL) async throws {
        await server.appendRoute("GET /*", to: DirectoryHTTPHandler(root: root))
        Task {
            try await server.start()
        }
        try await server.waitUntilListening()
    }

    func stop() async {
        if await server.isListening {
            await server.stop(timeout: 2)
        }
    }

    func getAddress() async -> Socket.Address? {
        await server.listeningAddress
    }
}
