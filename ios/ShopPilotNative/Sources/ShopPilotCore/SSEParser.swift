import Foundation

public enum ChatStreamEvent: Equatable {
    case meta(StreamMeta)
    case delta(String)
    case final(ChatResponse)
    case done
    case error(String)
}

public struct StreamMeta: Decodable, Equatable {
    public let sessionId: String
    public let intent: String?
    public let createdAt: Int?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case intent
        case createdAt = "created_at"
    }
}

public final class SSEParser {
    private var buffer = ""
    private let decoder = JSONDecoder()

    public init() {}

    public func append(_ chunk: String) throws -> [ChatStreamEvent] {
        buffer += chunk
        let normalized = buffer.replacingOccurrences(of: "\r\n", with: "\n")
        let parts = normalized.components(separatedBy: "\n\n")
        buffer = parts.last ?? ""

        return try parts.dropLast().compactMap(parseBlock)
    }

    public func flush() throws -> [ChatStreamEvent] {
        guard !buffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        let event = try parseBlock(buffer)
        buffer = ""
        return event.map { [$0] } ?? []
    }

    private func parseBlock(_ block: String) throws -> ChatStreamEvent? {
        var eventName = ""
        var dataLines: [String] = []

        for line in block.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix("event:") {
                eventName = line.dropFirst("event:".count).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                dataLines.append(line.dropFirst("data:".count).trimmingCharacters(in: .whitespaces))
            }
        }

        guard !eventName.isEmpty, !dataLines.isEmpty else {
            return nil
        }

        let data = Data(dataLines.joined(separator: "\n").utf8)
        switch eventName {
        case "meta":
            return .meta(try decoder.decode(StreamMeta.self, from: data))
        case "delta":
            let payload = try decoder.decode(DeltaPayload.self, from: data)
            return .delta(payload.text)
        case "final":
            return .final(try decoder.decode(ChatResponse.self, from: data))
        case "done":
            return .done
        case "error":
            let payload = try decoder.decode(ErrorPayload.self, from: data)
            return .error(payload.message)
        default:
            return nil
        }
    }
}

private struct DeltaPayload: Decodable {
    let text: String
}

private struct ErrorPayload: Decodable {
    let message: String
}

private extension Substring {
    func trimmingCharacters(in set: CharacterSet) -> String {
        String(self).trimmingCharacters(in: set)
    }
}
