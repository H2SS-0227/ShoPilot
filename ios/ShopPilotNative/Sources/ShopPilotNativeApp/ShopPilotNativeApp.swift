import SwiftUI

#if canImport(ShopPilotCore)
import ShopPilotCore
#endif

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
    @State private var selectedTab: BottomTab = .chat

    var body: some View {
        ZStack {
            MeshBackground()

            VStack(spacing: 0) {
                TopAppBar(
                    cartCount: cart.count,
                    showOnlineDot: !viewModel.messages.isEmpty,
                    onMenu: {},
                    onCart: { cartOpen = true }
                )

                if viewModel.messages.isEmpty {
                    HomeCanvas(inputText: $viewModel.inputText, onSend: { viewModel.send() }, onPrompt: viewModel.send)
                } else {
                    ChatCanvas(
                        viewModel: viewModel,
                        selectedTab: $selectedTab,
                        onOpenProduct: { selectedProduct = $0 },
                        onAddProduct: addToCart,
                        onCompare: { compareOpen = true },
                        onCart: { cartOpen = true }
                    )
                }
            }
        }
        .preferredColorScheme(.light)
        .sheet(item: $selectedProduct) { product in
            ProductDetailSheet(product: product, onAdd: { addToCart(product) })
                .presentationDetents([.height(760), .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $compareOpen) {
            CompareSheet(products: Array(viewModel.lastProducts.prefix(2)))
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $cartOpen) {
            CartDrawer(products: cart, onRemove: { product in
                cart.removeAll { $0.id == product.id }
            })
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    private func addToCart(_ product: Product) {
        guard !cart.contains(where: { $0.id == product.id }) else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            cart.append(product)
        }
    }
}

enum BottomTab: String, CaseIterable {
    case home
    case search
    case cart
    case profile
    case chat

    var icon: String {
        switch self {
        case .home: return "house"
        case .search: return "magnifyingglass"
        case .cart: return "cart"
        case .profile: return "person"
        case .chat: return "message.fill"
        }
    }

    var label: String {
        switch self {
        case .home: return "首页"
        case .search: return "搜索"
        case .cart: return "购物车"
        case .profile: return "我的"
        case .chat: return "聊天"
        }
    }
}

private enum ShopColors {
    static let primary = Color(hex: 0x4648D4)
    static let primaryContainer = Color(hex: 0x6063EE)
    static let secondary = Color(hex: 0x8127CF)
    static let secondaryContainer = Color(hex: 0x9C48EA)
    static let background = Color(hex: 0xFCF8FF)
    static let surface = Color(hex: 0xFCF8FF)
    static let surfaceLowest = Color(hex: 0xFFFFFF)
    static let surfaceLow = Color(hex: 0xF5F2FE)
    static let surfaceContainer = Color(hex: 0xEFECF8)
    static let surfaceHigh = Color(hex: 0xE9E6F3)
    static let surfaceHighest = Color(hex: 0xE4E1ED)
    static let onSurface = Color(hex: 0x1B1B23)
    static let onSurfaceVariant = Color(hex: 0x464554)
    static let outline = Color(hex: 0x767586)
    static let outlineVariant = Color(hex: 0xC7C4D7)
    static let error = Color(hex: 0xBA1A1A)
}

struct MeshBackground: View {
    var body: some View {
        ZStack {
            ShopColors.background.ignoresSafeArea()
            Circle()
                .fill(ShopColors.primaryContainer.opacity(0.13))
                .frame(width: 290, height: 290)
                .blur(radius: 26)
                .offset(x: -150, y: 120)
            Circle()
                .fill(ShopColors.secondaryContainer.opacity(0.13))
                .frame(width: 330, height: 330)
                .blur(radius: 30)
                .offset(x: 150, y: -180)
        }
    }
}

struct TopAppBar: View {
    let cartCount: Int
    let showOnlineDot: Bool
    let onMenu: () -> Void
    let onCart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            HStack {
                Button(action: onMenu) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(ShopColors.primary)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 7) {
                    Text("ShopPilot AI")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(ShopColors.onSurface)
                    if showOnlineDot {
                        Circle()
                            .fill(Color(hex: 0x22C55E))
                            .frame(width: 7, height: 7)
                            .shadow(color: Color(hex: 0x22C55E).opacity(0.5), radius: 6)
                    }
                }

                Spacer()

                Button(action: onCart) {
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(ShopColors.surfaceHigh)
                            .frame(width: 36, height: 36)
                        Image(systemName: cartCount > 0 ? "cart.fill" : "person.crop.circle")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(cartCount > 0 ? ShopColors.primary : ShopColors.onSurfaceVariant)
                            .frame(width: 36, height: 36)
                        if cartCount > 0 {
                            Text("\(cartCount)")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(width: 16, height: 16)
                                .background(ShopColors.secondaryContainer)
                                .clipShape(Circle())
                                .offset(x: 3, y: -4)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
        }
        .frame(height: 88)
        .background(.ultraThinMaterial.opacity(0.72))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ShopColors.outlineVariant.opacity(0.35))
                .frame(height: 0.6)
        }
    }
}

struct HomeCanvas: View {
    @Binding var inputText: String
    let onSend: () -> Void
    let onPrompt: (String) -> Void

    private let prompts: [(String, String, String)] = [
        ("headphones", "帮我选一款高性价比耳机", "headphones"),
        ("gift", "最近有什么适合送礼的香水?", "gift"),
        ("wand.and.stars", "我想对比一下这两款扫地机器人", "spark")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 10)

            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: [ShopColors.primary.opacity(0.12), ShopColors.secondary.opacity(0.14)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 86, height: 86)
                        .blur(radius: 16)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.76))
                        .frame(width: 72, height: 72)
                        .shadow(color: ShopColors.primary.opacity(0.22), radius: 22, y: 10)
                    Image(systemName: "sparkles")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(ShopColors.primary)
                }

                Text("ShopPilot AI")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [ShopColors.primary, ShopColors.secondary], startPoint: .leading, endPoint: .trailing))
                    .minimumScaleFactor(0.75)

                Text("会聊天、懂商品、能帮你做购买决策")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(ShopColors.onSurfaceVariant)
            }
            .padding(.top, 16)

            HeroSearchBar(text: $inputText, placeholder: "描述你想要寻找的商品或服务需求...", onSend: onSend)
                .padding(.horizontal, 18)
                .padding(.top, 26)

            Text("试着问我")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(ShopColors.onSurfaceVariant.opacity(0.72))
                .padding(.top, 24)

            VStack(spacing: 14) {
                ForEach(prompts, id: \.1) { item in
                    Button {
                        onPrompt(item.1)
                    } label: {
                        HomePromptCard(icon: item.0, title: item.1, tintKey: item.2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Spacer(minLength: 84)
        }
        .safeAreaInset(edge: .bottom) {
            BottomTabBar(selectedTab: .constant(.chat), cartCount: 0, onCart: {})
        }
    }
}

struct HomePromptCard: View {
    let icon: String
    let title: String
    let tintKey: String

    var tint: Color {
        tintKey == "gift" ? ShopColors.secondary : (tintKey == "spark" ? Color(hex: 0xB55D00) : ShopColors.primary)
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(ShopColors.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            Circle()
                .fill(ShopColors.surfaceContainer.opacity(0.65))
                .frame(width: 48, height: 48)
                .offset(x: 12, y: -18)
        }
        .padding(.leading, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, minHeight: 96)
        .background(Color.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 14, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.42), lineWidth: 1)
        )
    }
}

struct ChatCanvas: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var selectedTab: BottomTab
    let onOpenProduct: (Product) -> Void
    let onAddProduct: (Product) -> Void
    let onCompare: () -> Void
    let onCart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 18) {
                        ForEach(viewModel.messages) { message in
                            MessageCluster(message: message, onOpenProduct: onOpenProduct, onAddProduct: onAddProduct)
                                .id(message.id)
                        }

                        if let errorMessage = viewModel.errorMessage {
                            ErrorBanner(message: errorMessage)
                        }

                        if !viewModel.lastProducts.isEmpty {
                            ActionStrip(
                                referenceCount: viewModel.lastProducts.reduce(0) { $0 + $1.reviewReferences.count },
                                canCompare: viewModel.lastProducts.count >= 2,
                                onCompare: onCompare,
                                onCheaper: { viewModel.send("再便宜一点") }
                            )
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 16)
                    .padding(.bottom, 128)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation(.easeOut(duration: 0.28)) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            ChatInputDock(
                text: $viewModel.inputText,
                isStreaming: viewModel.isStreaming,
                onSend: { viewModel.send() },
                onCancel: viewModel.cancel
            )
        }
        .safeAreaInset(edge: .bottom) {
            BottomTabBar(selectedTab: $selectedTab, cartCount: viewModel.lastProducts.count, onCart: onCart)
        }
    }
}

struct MessageCluster: View {
    let message: ChatMessage
    let onOpenProduct: (Product) -> Void
    let onAddProduct: (Product) -> Void

    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 9) {
            HStack(alignment: .bottom, spacing: 8) {
                if message.role == .assistant {
                    AssistantAvatar()
                } else {
                    Spacer(minLength: 46)
                }

                MessageBubble(message: message)

                if message.role == .assistant {
                    Spacer(minLength: 40)
                }
            }

            if !message.products.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(message.products.enumerated()), id: \.element.id) { index, product in
                            ProductCardView(product: product, rank: index + 1, onOpen: { onOpenProduct(product) }, onAdd: { onAddProduct(product) })
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.leading, 42)
                    .padding(.trailing, 10)
                    .padding(.vertical, 4)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: message.products.count)
    }
}

struct AssistantAvatar: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [ShopColors.primary, ShopColors.secondaryContainer], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 34, height: 34)
            Image(systemName: "sparkles")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(color: ShopColors.primary.opacity(0.2), radius: 8, y: 5)
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        Text(message.text + (message.isStreaming ? "  ▍" : ""))
            .font(.system(size: 15, weight: message.role == .user ? .semibold : .regular))
            .foregroundStyle(message.role == .user ? .white : ShopColors.onSurface)
            .lineSpacing(4)
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            .background(
                Group {
                    if message.role == .user {
                        LinearGradient(colors: [ShopColors.primaryContainer, ShopColors.primary], startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        LinearGradient(colors: [ShopColors.surfaceContainer, ShopColors.surfaceLow], startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(message.role == .user ? Color.clear : ShopColors.outlineVariant.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: .black.opacity(message.role == .user ? 0.12 : 0.06), radius: 12, y: 8)
            .frame(maxWidth: 320, alignment: message.role == .user ? .trailing : .leading)
            .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
            .padding(.trailing, message.role == .user ? 8 : 0)
    }
}

struct ProductCardView: View {
    let product: Product
    let rank: Int
    let onOpen: () -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ZStack(alignment: .topLeading) {
                AsyncImage(url: resolvedImageURL(product.imageUrl)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ZStack {
                        ShopColors.surfaceContainer
                        Image(systemName: "bag")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(ShopColors.primary)
                    }
                }
                .frame(width: 222, height: 128)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                    Text("4.8")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(ShopColors.onSurface)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(8)
            }
            .onTapGesture(perform: onOpen)

            HStack(alignment: .top) {
                Text(product.name)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(ShopColors.onSurface)
                    .lineLimit(2)
                Spacer(minLength: 6)
                Text("¥\(Int(product.price))")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(ShopColors.primary)
            }

            HStack(spacing: 6) {
                TagPill(text: product.subCategory ?? product.category, tint: ShopColors.secondaryContainer)
                if product.reviewReferences.isEmpty == false {
                    TagPill(text: "测评参考", tint: ShopColors.primary)
                }
            }

            Text(product.reason ?? product.description)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ShopColors.onSurfaceVariant)
                .lineLimit(2)
                .lineSpacing(2)

            HStack(spacing: 8) {
                Button(action: onAdd) {
                    Label("加购", systemImage: "cart")
                        .font(.system(size: 12, weight: .heavy))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(.white)
                        .background(LinearGradient(colors: [ShopColors.primary, ShopColors.secondaryContainer], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onOpen) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(ShopColors.onSurfaceVariant)
                        .frame(width: 40, height: 36)
                        .background(ShopColors.surfaceLow)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .frame(width: 242)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 14, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(ShopColors.outlineVariant.opacity(0.22), lineWidth: 1)
        )
    }
}

struct TagPill: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.1))
            .clipShape(Capsule())
    }
}

struct ActionStrip: View {
    let referenceCount: Int
    let canCompare: Bool
    let onCompare: () -> Void
    let onCheaper: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onCompare) {
                Label("对比前两款", systemImage: "rectangle.split.2x1")
            }
            .disabled(!canCompare)

            Button(action: onCheaper) {
                Label("再便宜一点", systemImage: "arrow.down.forward")
            }

            Label("\(referenceCount) 条测评", systemImage: "play.rectangle")
        }
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(ShopColors.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.78))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.05), radius: 10, y: 6)
        .padding(.horizontal, 12)
    }
}

struct HeroSearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ShopColors.outline)
            TextField(placeholder, text: $text)
                .font(.system(size: 13))
                .onSubmit(onSend)
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(LinearGradient(colors: [ShopColors.primary, ShopColors.secondaryContainer], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 14)
        .padding(.trailing, 7)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.82))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 16, y: 10)
        .overlay(Capsule().stroke(Color.white.opacity(0.55), lineWidth: 1))
    }
}

struct ChatInputDock: View {
    @Binding var text: String
    let isStreaming: Bool
    let onSend: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if isStreaming {
                Button(action: onCancel) {
                    Label("停止生成", systemImage: "stop.circle")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(ShopColors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(ShopColors.primary.opacity(0.09))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Image(systemName: "photo")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ShopColors.onSurfaceVariant)
                    .frame(width: 34, height: 34)

                TextField("Message ShopPilot AI...", text: $text)
                    .font(.system(size: 13, weight: .medium))
                        .onSubmit(onSend)

                Button(action: onSend) {
                    Image(systemName: isStreaming ? "stop.circle" : "paperplane.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 37, height: 37)
                        .background(LinearGradient(colors: [ShopColors.primary, ShopColors.secondaryContainer], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isStreaming)
            }
            .padding(.leading, 8)
            .padding(.trailing, 7)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 14, y: 8)
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(ShopColors.outlineVariant.opacity(0.34), lineWidth: 1))
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 2)
        .background(ShopColors.background.opacity(0.78))
    }
}

struct BottomTabBar: View {
    @Binding var selectedTab: BottomTab
    let cartCount: Int
    let onCart: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach([BottomTab.home, .search, .chat, .cart, .profile], id: \.self) { tab in
                Button {
                    selectedTab = tab
                    if tab == .cart { onCart() }
                } label: {
                    VStack(spacing: 3) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(selectedTab == tab ? .white : ShopColors.onSurface)
                                .frame(width: tab == .chat ? 42 : 30, height: 30)
                                .background(selectedTab == tab ? ShopColors.primary : Color.clear)
                                .clipShape(Circle())
                            if tab == .cart && cartCount > 0 {
                                Text("\(cartCount)")
                                    .font(.system(size: 8, weight: .heavy))
                                    .foregroundStyle(.white)
                                    .frame(width: 14, height: 14)
                                    .background(ShopColors.secondaryContainer)
                                    .clipShape(Circle())
                                    .offset(x: 4, y: -3)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 6)
        .padding(.bottom, 6)
        .background(Color.white.opacity(0.86))
        .overlay(alignment: .top) {
            Rectangle().fill(ShopColors.outlineVariant.opacity(0.36)).frame(height: 0.6)
        }
    }
}

struct ProductDetailSheet: View {
    let product: Product
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            ShopColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Button { dismiss() } label: {
                            Label("Back to Chat", systemImage: "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(ShopColors.onSurfaceVariant)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Image(systemName: "heart")
                            .font(.system(size: 19, weight: .semibold))
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .padding(.top, 10)

                    AsyncImage(url: resolvedImageURL(product.imageUrl)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        ZStack {
                            ShopColors.surfaceContainer
                            Image(systemName: "bag")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundStyle(ShopColors.primary)
                        }
                    }
                    .frame(height: 270)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Text(product.brand?.uppercased() ?? product.category.uppercased())
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(ShopColors.primary)

                    HStack(alignment: .top) {
                        Text(product.name)
                            .font(.system(size: 25, weight: .heavy))
                            .foregroundStyle(ShopColors.onSurface)
                            .lineLimit(3)
                        Spacer(minLength: 12)
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("¥\(Int(product.price))")
                                .font(.system(size: 25, weight: .heavy))
                            Label("4.9 (128)", systemImage: "star.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: 0xB55D00))
                        }
                    }

                    RecommendationCard(product: product)

                    if !product.reviewReferences.isEmpty {
                        VStack(alignment: .leading, spacing: 9) {
                            Text("真实测评参考")
                                .font(.system(size: 15, weight: .heavy))
                            ForEach(product.reviewReferences) { reference in
                                if let url = URL(string: reference.url) {
                                    Link(destination: url) {
                                        HStack(spacing: 10) {
                                            Image(systemName: "play.rectangle.fill")
                                                .foregroundStyle(ShopColors.primary)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(reference.title)
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundStyle(ShopColors.onSurface)
                                                    .lineLimit(1)
                                                Text(reference.platform)
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundStyle(ShopColors.onSurfaceVariant)
                                            }
                                            Spacer()
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(ShopColors.onSurfaceVariant)
                                        }
                                        .padding(12)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }
                                }
                            }
                        }
                    }

                    Spacer(minLength: 96)
                }
                .padding(.horizontal, 16)
            }

            HStack(spacing: 12) {
                Button {} label: {
                    Image(systemName: "message")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(ShopColors.onSurfaceVariant)
                        .frame(width: 54, height: 54)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(ShopColors.outlineVariant.opacity(0.32), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button(action: onAdd) {
                    Label("Add to Cart - ¥\(Int(product.price))", systemImage: "bag")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(LinearGradient(colors: [ShopColors.primary, ShopColors.secondaryContainer], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: ShopColors.primary.opacity(0.26), radius: 12, y: 8)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(.ultraThinMaterial)
        }
    }
}

struct RecommendationCard: View {
    let product: Product

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [ShopColors.primary, ShopColors.secondaryContainer], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 42, height: 42)
                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Why ShopPilot recommends this")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(ShopColors.onSurface)
                Text(product.reason ?? product.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ShopColors.onSurfaceVariant)
                    .lineSpacing(3)
                    .lineLimit(6)
            }
        }
        .padding(16)
        .background(LinearGradient(colors: [ShopColors.secondaryContainer.opacity(0.12), Color.white.opacity(0.94)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct CompareSheet: View {
    let products: [Product]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ShopColors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(ShopColors.primary)
                    Spacer()
                    VStack(spacing: 2) {
                        Text("Compare Tents")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(ShopColors.onSurface)
                        Text("Comparing options for your shopping plan")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(ShopColors.onSurfaceVariant)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(ShopColors.onSurface)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .frame(height: 64)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(products.prefix(2)) { product in
                                CompareProductCard(product: product)
                            }
                        }
                        .padding(.horizontal, 12)

                        VStack(alignment: .leading, spacing: 9) {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle().fill(ShopColors.primary).frame(width: 36, height: 36)
                                    Image(systemName: "sparkles").foregroundStyle(.white)
                                }
                                Text("ShopPilot Conclusion")
                                    .font(.system(size: 13, weight: .heavy))
                                    .foregroundStyle(ShopColors.primary)
                            }
                            Text("基于预算、类目、推荐理由和测评参考，建议优先选择更贴合你当前场景的商品。若预算敏感，可以继续让我筛选更便宜的选项。")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ShopColors.onSurfaceVariant)
                                .lineSpacing(3)
                            Button("Ask a follow-up question") {}
                                .font(.system(size: 12, weight: .bold))
                                .buttonStyle(.bordered)
                        }
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .padding(.horizontal, 12)
                    }
                    .padding(.bottom, 96)
                }

                BottomTabBar(selectedTab: .constant(.search), cartCount: 0, onCart: {})
            }
        }
    }
}

struct CompareProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            AsyncImage(url: resolvedImageURL(product.imageUrl)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                ShopColors.surfaceContainer
            }
            .frame(height: 132)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(product.name)
                .font(.system(size: 12, weight: .heavy))
                .lineLimit(3)
            Text("¥\(Int(product.price))")
                .font(.system(size: 21, weight: .heavy))
                .foregroundStyle(ShopColors.primary)

            CompareRow(label: "Core Strengths", text: product.subCategory ?? product.category)
            CompareRow(label: "Scenario Fit", text: product.reason ?? "基于商品库匹配")
            CompareRow(label: "Review", text: "\(product.reviewReferences.count) 条参考")
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ShopColors.outlineVariant.opacity(0.28), lineWidth: 1))
    }
}

struct CompareRow: View {
    let label: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(label, systemImage: "checkmark.circle")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(ShopColors.onSurfaceVariant)
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(ShopColors.onSurfaceVariant)
                .lineLimit(3)
        }
    }
}

struct CartDrawer: View {
    let products: [Product]
    let onRemove: (Product) -> Void
    @Environment(\.dismiss) private var dismiss

    private var subtotal: Double {
        products.reduce(0) { $0 + $1.price }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ShopColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "cart")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(ShopColors.primary)
                    Text("Your Cart")
                        .font(.system(size: 22, weight: .heavy))
                    Text("\(products.count)")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(ShopColors.primary)
                        .clipShape(Circle())
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(ShopColors.onSurface)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .frame(height: 64)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if products.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "cart")
                                    .font(.system(size: 44, weight: .semibold))
                                    .foregroundStyle(ShopColors.outline)
                                Text("购物车还是空的")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(ShopColors.onSurface)
                                Text("从推荐商品卡片点击加购后会出现在这里。")
                                    .font(.system(size: 13))
                                    .foregroundStyle(ShopColors.onSurfaceVariant)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 90)
                        } else {
                            ForEach(products) { product in
                                CartItemRow(product: product, onRemove: { onRemove(product) })
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 280)
                }
            }

            VStack(spacing: 15) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(ShopColors.primary)
                        .frame(width: 32, height: 32)
                        .background(ShopColors.primary.opacity(0.09))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Customer who bought these also looked at protective cases.")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(ShopColors.onSurface)
                        Text("View suggestions")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(ShopColors.primary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(ShopColors.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(ShopColors.primary.opacity(0.18), lineWidth: 1))

                HStack {
                    Text("Subtotal")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ShopColors.onSurfaceVariant)
                    Spacer()
                    Text("¥\(Int(subtotal))")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(ShopColors.onSurface)
                }
                Text("Shipping and taxes calculated at checkout.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ShopColors.onSurfaceVariant)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {} label: {
                    Label("Confirm Order", systemImage: "arrow.right")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(LinearGradient(colors: [ShopColors.primary, ShopColors.secondaryContainer], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(.ultraThinMaterial)
        }
    }
}

struct CartItemRow: View {
    let product: Product
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: resolvedImageURL(product.imageUrl)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                ShopColors.surfaceContainer
            }
            .frame(width: 76, height: 76)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(product.name)
                    .font(.system(size: 13, weight: .heavy))
                    .lineLimit(2)
                Text(product.subCategory ?? product.category)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ShopColors.onSurfaceVariant)
                Text("¥\(Int(product.price))")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(ShopColors.primary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onRemove) {
                    Image(systemName: "minus")
                }
                Text("1")
                Image(systemName: "plus")
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(ShopColors.onSurfaceVariant)
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(ShopColors.surfaceContainer)
            .clipShape(Capsule())
        }
        .padding(9)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(ShopColors.outlineVariant.opacity(0.3), lineWidth: 1))
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(ShopColors.error)
            .padding(12)
            .background(Color(hex: 0xFFDAD6))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 12)
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
