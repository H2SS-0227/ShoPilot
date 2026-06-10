import XCTest
@testable import ShopPilotCore

final class SSEParserTests: XCTestCase {
    func testParserEmitsMetaDeltaFinalDone() throws {
        let parser = SSEParser()
        let stream = """
        event: meta
        data: {"session_id":"ios-demo-session","intent":"recommend","created_at":1781090000}

        event: delta
        data: {"text":"推荐"}

        event: delta
        data: {"text":"咖啡"}

        event: final
        data: {"type":"final","intent":"recommend","answer":"推荐咖啡","products":[{"id":"p_food_001","name":"冷萃咖啡","category":"食品生活","sub_category":"咖啡","brand":"Demo","price":39,"currency":"CNY","description":"低糖冷萃","image_url":"/assets/products/4_食品生活/images/p_food_001_live.jpg","features":["低糖"],"tags":["咖啡"],"review_references":[{"title":"TikTok 测评","url":"https://www.tiktok.com/demo","platform":"tiktok","author":null,"summary":null}],"reason":"符合预算"}],"comparison":[],"cart_action":{"type":"none","product_id":null,"message":null},"suggested_actions":["加入购物车"]}

        event: done
        data: {"ok":true}

        """

        let events = try parser.append(stream)

        XCTAssertEqual(events.count, 5)
        XCTAssertEqual(events[0], .meta(StreamMeta(sessionId: "ios-demo-session", intent: "recommend", createdAt: 1781090000)))
        XCTAssertEqual(events[1], .delta("推荐"))
        XCTAssertEqual(events[2], .delta("咖啡"))

        guard case .final(let response) = events[3] else {
            return XCTFail("Expected final response")
        }
        XCTAssertEqual(response.answer, "推荐咖啡")
        XCTAssertEqual(response.products.first?.reviewReferences.first?.platform, "tiktok")
        XCTAssertEqual(events[4], .done)
    }

    func testParserHandlesSplitChunks() throws {
        let parser = SSEParser()

        let first = try parser.append("event: delta\ndata: {\"text\":\"流")
        XCTAssertTrue(first.isEmpty)

        let second = try parser.append("式\"}\n\n")
        XCTAssertEqual(second, [.delta("流式")])
    }
}
