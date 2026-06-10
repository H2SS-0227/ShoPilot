import Foundation
import Combine

@MainActor
public final class ChatViewModel: ObservableObject {
    @Published public private(set) var messages: [ChatMessage]
    @Published public private(set) var lastProducts: [Product]
    @Published public private(set) var isStreaming: Bool
    @Published public var inputText: String
    @Published public var errorMessage: String?

    private let apiClient: ShopPilotAPIClientProtocol
    private let sessionId: String
    private var streamTask: Task<Void, Never>?

    public init(
        apiClient: ShopPilotAPIClientProtocol = ShopPilotAPIClient(),
        sessionId: String = "ios-demo-session"
    ) {
        self.apiClient = apiClient
        self.sessionId = sessionId
        self.messages = []
        self.lastProducts = []
        self.isStreaming = false
        self.inputText = "推荐一款 200 元以内的咖啡，并给我参考真实测评链接"
    }

    public func send(_ text: String? = nil) {
        let prompt = (text ?? inputText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !isStreaming else { return }

        inputText = ""
        errorMessage = nil
        isStreaming = true
        messages.append(ChatMessage(role: .user, text: prompt))

        let assistantId = UUID()
        messages.append(ChatMessage(id: assistantId, role: .assistant, text: "正在理解需求并检索商品库...", isStreaming: true))

        streamTask = Task { [apiClient, sessionId] in
            do {
                var hasDelta = false
                for try await event in apiClient.streamMessage(prompt, sessionId: sessionId) {
                    switch event {
                    case .meta:
                        break
                    case .delta(let text):
                        hasDelta = true
                        appendDelta(text, to: assistantId)
                    case .final(let response):
                        applyFinal(response, to: assistantId)
                    case .done:
                        finish(assistantId: assistantId)
                    case .error(let message):
                        fail(message, assistantId: assistantId)
                    }
                }

                if !hasDelta {
                    markNotStreaming(assistantId: assistantId)
                }
            } catch is CancellationError {
                cancelAssistantMessage(assistantId: assistantId)
            } catch {
                await fallbackToJSON(prompt: prompt, assistantId: assistantId)
            }
        }
    }

    public func cancel() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }

    public func reset() {
        streamTask?.cancel()
        streamTask = nil
        messages = []
        lastProducts = []
        errorMessage = nil
        isStreaming = false
        inputText = "推荐一款 200 元以内的咖啡，并给我参考真实测评链接"
    }

    private func appendDelta(_ text: String, to assistantId: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == assistantId }) else { return }
        if messages[index].text == "正在理解需求并检索商品库..." {
            messages[index].text = text
        } else {
            messages[index].text += text
        }
    }

    private func applyFinal(_ response: ChatResponse, to assistantId: UUID) {
        lastProducts = response.products
        guard let index = messages.firstIndex(where: { $0.id == assistantId }) else { return }
        messages[index].text = response.answer
        messages[index].products = response.products
        messages[index].isStreaming = false
    }

    private func finish(assistantId: UUID) {
        markNotStreaming(assistantId: assistantId)
        isStreaming = false
    }

    private func fail(_ message: String, assistantId: UUID) {
        errorMessage = message
        markNotStreaming(assistantId: assistantId)
        isStreaming = false
    }

    private func markNotStreaming(assistantId: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == assistantId }) else { return }
        messages[index].isStreaming = false
    }

    private func cancelAssistantMessage(assistantId: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == assistantId }) else { return }
        messages[index].text = "已取消本次生成，可以修改需求后重新发送。"
        messages[index].isStreaming = false
        isStreaming = false
    }

    private func fallbackToJSON(prompt: String, assistantId: UUID) async {
        do {
            let response = try await apiClient.sendMessage(prompt, sessionId: sessionId)
            applyFinal(response, to: assistantId)
        } catch {
            fail("接口暂时不可用，请确认后端服务已启动。", assistantId: assistantId)
        }
        isStreaming = false
    }
}
