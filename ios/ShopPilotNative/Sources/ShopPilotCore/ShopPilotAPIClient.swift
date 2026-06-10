import Foundation

public protocol ShopPilotAPIClientProtocol {
    func sendMessage(_ message: String, sessionId: String) async throws -> ChatResponse
    func streamMessage(_ message: String, sessionId: String) -> AsyncThrowingStream<ChatStreamEvent, Error>
}

public final class ShopPilotAPIClient: ShopPilotAPIClientProtocol {
    public enum APIEnvironment: String, CaseIterable, Identifiable {
        case local
        case simulator
        case lan
        case deployed

        public var id: String { rawValue }

        public var urlString: String {
            switch self {
            case .local, .simulator:
                return "http://127.0.0.1:8000"
            case .lan:
                return "http://192.168.1.2:8000"
            case .deployed:
                return "https://your-shoppilot-demo.vercel.app"
            }
        }
    }

    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(baseURL: URL = URL(string: APIEnvironment.local.urlString)!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func sendMessage(_ message: String, sessionId: String = "ios-demo-session") async throws -> ChatResponse {
        var request = makeChatRequest()
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(ChatRequest(sessionId: sessionId, message: message, stream: false))

        let (data, response) = try await session.data(for: request)
        try validate(response)
        return try decoder.decode(ChatResponse.self, from: data)
    }

    public func streamMessage(_ message: String, sessionId: String = "ios-demo-session") -> AsyncThrowingStream<ChatStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = makeChatRequest()
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.httpBody = try encoder.encode(ChatRequest(sessionId: sessionId, message: message, stream: true))

                    let (bytes, response) = try await session.bytes(for: request)
                    try validate(response)

                    let parser = SSEParser()
                    for try await line in bytes.lines {
                        let events = try parser.append(line + "\n")
                        for event in events {
                            continuation.yield(event)
                        }
                    }

                    for event in try parser.flush() {
                        continuation.yield(event)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func makeChatRequest() -> URLRequest {
        var request = URLRequest(url: baseURL.appending(path: "/api/chat"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
