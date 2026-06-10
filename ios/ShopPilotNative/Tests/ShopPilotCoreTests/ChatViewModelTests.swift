import XCTest
@testable import ShopPilotCore

@MainActor
final class ChatViewModelTests: XCTestCase {
    func testViewModelAppliesStreamDeltaAndFinalResponse() async throws {
        let response = ChatResponse.fixture(answer: "推荐这款咖啡", products: [.fixture()])
        let viewModel = ChatViewModel(
            apiClient: MockAPIClient(events: [.delta("推荐"), .delta("这款咖啡"), .final(response), .done]),
            sessionId: "test-session"
        )

        viewModel.send("推荐咖啡")
        try await Task.sleep(nanoseconds: 80_000_000)

        XCTAssertFalse(viewModel.isStreaming)
        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages.last?.text, "推荐这款咖啡")
        XCTAssertEqual(viewModel.messages.last?.products.first?.id, "p_food_001")
        XCTAssertEqual(viewModel.lastProducts.count, 1)
    }
}

private struct MockAPIClient: ShopPilotAPIClientProtocol {
    let events: [ChatStreamEvent]

    func sendMessage(_ message: String, sessionId: String) async throws -> ChatResponse {
        ChatResponse.fixture(answer: "JSON fallback", products: [])
    }

    func streamMessage(_ message: String, sessionId: String) -> AsyncThrowingStream<ChatStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                for event in events {
                    continuation.yield(event)
                }
                continuation.finish()
            }
        }
    }
}

private extension ChatResponse {
    static func fixture(answer: String, products: [Product]) -> ChatResponse {
        ChatResponse(
            type: "final",
            intent: "recommend",
            answer: answer,
            products: products,
            comparison: [],
            cartAction: nil,
            suggestedActions: ["加入购物车"]
        )
    }
}

private extension Product {
    static func fixture() -> Product {
        Product(
            id: "p_food_001",
            name: "冷萃咖啡",
            category: "食品生活",
            subCategory: "咖啡",
            brand: "Demo",
            price: 39,
            currency: "CNY",
            description: "低糖冷萃",
            imageUrl: "/assets/products/4_食品生活/images/p_food_001_live.jpg",
            features: ["低糖"],
            tags: ["咖啡"],
            reviewReferences: [],
            reason: "符合预算"
        )
    }
}
