import ShopPilotCore
import SwiftUI

@main
struct ShopPilotNativeApp: App {
    var body: some Scene {
        WindowGroup {
            ChatScreen()
        }
    }
}

struct ChatScreen: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var selectedProduct: Product?
    @State private var compareOpen = false
    @State private var cartOpen = false
    @State private var cart: [Product] = []

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(hex: 0xFCF8FF), Color(hex: 0xF2EDFF)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            if viewModel.messages.isEmpty {
                                EmptyStateView(onPrompt: viewModel.send)
                            }

                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                if !message.products.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(message.products) { product in
                                                ProductCardView(product: product) {
                                                    selectedProduct = product
                                                } onAdd: {
                                                    addToCart(product)
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                            }

                            if let errorMessage = viewModel.errorMessage {
                                ErrorBanner(message: errorMessage)
                            }
                        }
                        .padding(.vertical, 18)
                    }

                    InputDock(
                        text: $viewModel.inputText,
                        isStreaming: viewModel.isStreaming,
                        onSend: { viewModel.send() },
                        onCancel: viewModel.cancel
                    )
                }
            }
            .navigationTitle("ShopPilot AI")
            .toolbar {
                ToolbarItem {
                    Button {
                        compareOpen = true
                    } label: {
                        Label("对比", systemImage: "rectangle.split.2x1")
                    }
                    .disabled(viewModel.lastProducts.count < 2)
                }
                ToolbarItem {
                    Button {
                        cartOpen = true
                    } label: {
                        Label("购物车", systemImage: "cart")
                    }
                }
            }
            .sheet(item: $selectedProduct) { product in
                ProductDetailView(product: product) {
                    addToCart(product)
                }
            }
            .sheet(isPresented: $compareOpen) {
                CompareSheet(products: Array(viewModel.lastProducts.prefix(2)))
            }
            .sheet(isPresented: $cartOpen) {
                CartSheet(products: cart) { product in
                    cart.removeAll { $0.id == product.id }
                }
            }
        }
    }

    private func addToCart(_ product: Product) {
        guard !cart.contains(where: { $0.id == product.id }) else { return }
        cart.append(product)
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 42)
            }

            Text(message.text + (message.isStreaming ? " ▍" : ""))
                .font(.system(size: 15, weight: message.role == .user ? .semibold : .regular))
                .foregroundStyle(message.role == .user ? .white : Color(hex: 0x1B1B23))
                .lineSpacing(4)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(message.role == .user ? Color(hex: 0x4648D4) : .white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(message.role == .user ? 0 : 0.08), radius: 14, y: 8)

            if message.role == .assistant {
                Spacer(minLength: 42)
            }
        }
        .padding(.horizontal)
    }
}

struct EmptyStateView: View {
    let prompts = [
        "推荐一款 200 元以内的咖啡，并给我参考真实测评链接",
        "推荐适合油皮的防晒",
        "推荐一双适合通勤的跑步鞋"
    ]
    let onPrompt: (String) -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(Color(hex: 0x4648D4))
            Text("今天想买点什么？")
                .font(.title2.bold())
            Text("告诉我预算、场景、偏好或排除项，我会从本地商品库中推荐可信商品。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            ForEach(prompts, id: \.self) { prompt in
                Button(prompt) {
                    onPrompt(prompt)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: 0x4648D4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.white.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal)
    }
}

struct ProductCardView: View {
    let product: Product
    let onOpen: () -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AsyncImage(url: resolvedImageURL(product.imageUrl)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                ZStack {
                    Color(hex: 0xEFECF8)
                    Image(systemName: "bag")
                        .foregroundStyle(Color(hex: 0x4648D4))
                }
            }
            .frame(height: 118)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Text(product.name)
                .font(.system(size: 15, weight: .bold))
                .lineLimit(2)
            Text("¥\(Int(product.price))")
                .font(.title3.bold())
                .foregroundStyle(Color(hex: 0x4648D4))
            Text(product.reason ?? product.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Button("详情", action: onOpen)
                Button("加入", action: onAdd)
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: 0x4648D4))
            }
            .font(.caption.bold())
        }
        .padding(12)
        .frame(width: 220)
        .background(.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }
}

struct ProductDetailView: View {
    let product: Product
    let onAdd: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: resolvedImageURL(product.imageUrl)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color(hex: 0xEFECF8)
                }
                .frame(height: 230)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                Text(product.name)
                    .font(.title2.bold())
                Text("¥\(Int(product.price))")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color(hex: 0x4648D4))
                Text(product.description)
                    .foregroundStyle(.secondary)

                if !product.reviewReferences.isEmpty {
                    Text("真实测评参考")
                        .font(.headline)
                    ForEach(product.reviewReferences) { reference in
                        Link(destination: URL(string: reference.url)!) {
                            Label(reference.title, systemImage: "play.rectangle")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(hex: 0xEFECF8))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }

                Button("加入购物车", action: onAdd)
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: 0x4648D4))
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .presentationDetents([.medium, .large])
    }
}

struct CompareSheet: View {
    let products: [Product]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("商品对比")
                .font(.title2.bold())
            HStack(spacing: 12) {
                ForEach(products) { product in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.name)
                            .font(.headline)
                            .lineLimit(2)
                        Text("¥\(Int(product.price))")
                            .foregroundStyle(Color(hex: 0x4648D4))
                            .font(.title3.bold())
                        Text(product.reason ?? "基于商品库匹配")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(hex: 0xFCF8FF))
        .presentationDetents([.medium, .large])
    }
}

struct CartSheet: View {
    let products: [Product]
    let onRemove: (Product) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(products) { product in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(product.name).font(.headline)
                            Text("¥\(Int(product.price))").foregroundStyle(Color(hex: 0x4648D4))
                        }
                        Spacer()
                        Button("移除") {
                            onRemove(product)
                        }
                    }
                }
            }
            .navigationTitle("购物车")
        }
    }
}

struct InputDock: View {
    @Binding var text: String
    let isStreaming: Bool
    let onSend: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if isStreaming {
                Button {
                    onCancel()
                } label: {
                    Label("停止生成", systemImage: "stop.circle")
                }
                .font(.caption.bold())
                .foregroundStyle(Color(hex: 0x4648D4))
            }

            HStack {
                TextField("描述你想要寻找的商品或需求...", text: $text)
                    .textFieldStyle(.plain)
                    .submitLabel(.send)
                    .onSubmit(onSend)
                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Color(hex: 0x4648D4))
                        .clipShape(Circle())
                }
                .disabled(isStreaming)
            }
            .padding(10)
            .background(.white.opacity(0.92))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.08), radius: 14, y: 8)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.caption.bold())
            .foregroundStyle(.red)
            .padding()
            .background(Color.red.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal)
    }
}

private func resolvedImageURL(_ path: String?) -> URL? {
    guard let path, !path.isEmpty else { return nil }
    if path.hasPrefix("http://") || path.hasPrefix("https://") {
        return URL(string: path)
    }

    let encodedPath = path
        .split(separator: "/", omittingEmptySubsequences: false)
        .map { String($0).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }
        .joined(separator: "/")
    return URL(string: "http://127.0.0.1:8000\(encodedPath)")
}

private extension Color {
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}
