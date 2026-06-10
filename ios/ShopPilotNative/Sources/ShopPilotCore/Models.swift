import Foundation

public struct ChatRequest: Encodable {
    public let sessionId: String
    public let message: String
    public let stream: Bool

    public init(sessionId: String = "ios-demo-session", message: String, stream: Bool = true) {
        self.sessionId = sessionId
        self.message = message
        self.stream = stream
    }

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case message
        case stream
    }
}

public struct ChatResponse: Decodable, Equatable {
    public let type: String?
    public let intent: String
    public let answer: String
    public let products: [Product]
    public let comparison: [ComparisonRow]
    public let cartAction: CartAction?
    public let suggestedActions: [String]

    enum CodingKeys: String, CodingKey {
        case type
        case intent
        case answer
        case products
        case comparison
        case cartAction = "cart_action"
        case suggestedActions = "suggested_actions"
    }
}

public struct Product: Decodable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let category: String
    public let subCategory: String?
    public let brand: String?
    public let price: Double
    public let currency: String
    public let description: String
    public let imageUrl: String?
    public let features: [String]
    public let tags: [String]
    public let reviewReferences: [ReviewReference]
    public let reason: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case subCategory = "sub_category"
        case brand
        case price
        case currency
        case description
        case imageUrl = "image_url"
        case features
        case tags
        case reviewReferences = "review_references"
        case reason
    }
}

public struct ReviewReference: Decodable, Identifiable, Equatable {
    public var id: String { url }
    public let title: String
    public let url: String
    public let platform: String
    public let author: String?
    public let summary: String?
}

public struct ComparisonRow: Decodable, Equatable {
    public let dimension: String
    public let items: [ComparisonItem]
}

public struct ComparisonItem: Decodable, Equatable {
    public let productId: String
    public let value: String

    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case value
    }
}

public struct CartAction: Decodable, Equatable {
    public let type: String?
    public let productId: String?
    public let message: String?

    enum CodingKeys: String, CodingKey {
        case type
        case productId = "product_id"
        case message
    }
}

public struct ChatMessage: Identifiable, Equatable {
    public enum Role: Equatable {
        case user
        case assistant
    }

    public let id: UUID
    public let role: Role
    public var text: String
    public var products: [Product]
    public var isStreaming: Bool

    public init(id: UUID = UUID(), role: Role, text: String, products: [Product] = [], isStreaming: Bool = false) {
        self.id = id
        self.role = role
        self.text = text
        self.products = products
        self.isStreaming = isStreaming
    }
}
