import { useMemo, useRef, useState } from "react";
import { ActivityIndicator, Image, KeyboardAvoidingView, Modal, Platform, Pressable, SafeAreaView, ScrollView, StyleSheet, Text, TextInput, View } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons } from "@expo/vector-icons";
import { ChatBubble } from "../components/chat/ChatBubble";
import { CartDrawer } from "../components/cart/CartDrawer";
import { ComparePanel } from "../components/compare/ComparePanel";
import { ProductCard } from "../components/product/ProductCard";
import { ReviewReferenceCard } from "../components/product/ReviewReferenceCard";
import { sendChatMessage, streamChatMessage } from "../services/api";
import type { ChatMessage } from "../types/chat";
import type { Product } from "../types/product";
import { colors, radius, shadow, spacing } from "../theme/tokens";
import { getProductImageUri } from "../utils/productImage";

const quickPrompts = [
  "推荐一款 200 元以内的咖啡，并给我参考真实测评链接",
  "推荐适合油皮的防晒",
  "推荐一双适合通勤的跑步鞋",
];

export function ChatScreen() {
  const [started, setStarted] = useState(false);
  const [input, setInput] = useState(quickPrompts[0]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [lastPrompt, setLastPrompt] = useState("");
  const [toast, setToast] = useState("");
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [lastProducts, setLastProducts] = useState<Product[]>([]);
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [cartOpen, setCartOpen] = useState(false);
  const [compareOpen, setCompareOpen] = useState(false);
  const [cart, setCart] = useState<Product[]>([]);
  const abortControllerRef = useRef<AbortController | null>(null);

  const referenceCount = useMemo(() => lastProducts.reduce((sum, item) => sum + (item.review_references?.length || 0), 0), [lastProducts]);

  async function submit(prompt = input) {
    const text = prompt.trim();
    if (!text || loading) return;
    const userMessageId = `u-${Date.now()}`;
    const assistantMessageId = `a-${Date.now()}`;
    let receivedDelta = false;

    setStarted(true);
    setInput("");
    setError("");
    setLastPrompt(text);
    setMessages((prev) => [
      ...prev,
      { id: userMessageId, role: "user", text },
      { id: assistantMessageId, role: "assistant", text: "正在理解需求并检索商品库...", streaming: true },
    ]);
    setLoading(true);

    const controller = new AbortController();
    abortControllerRef.current = controller;

    try {
      await streamChatMessage(
        text,
        "demo-session",
        {
          onDelta: (chunk) => {
            receivedDelta = true;
            setMessages((prev) =>
              prev.map((message) =>
                message.id === assistantMessageId
                  ? { ...message, text: message.text === "正在理解需求并检索商品库..." ? chunk : `${message.text}${chunk}` }
                  : message,
              ),
            );
          },
          onFinal: (response) => {
            setLastProducts(response.products || []);
            setMessages((prev) =>
              prev.map((message) =>
                message.id === assistantMessageId
                  ? { ...message, text: response.answer, products: response.products, streaming: false }
                  : message,
              ),
            );
          },
          onDone: () => {
            setLoading(false);
          },
          onError: (message) => {
            setError(message || "流式响应失败，请稍后重试。");
            setMessages((prev) => prev.map((item) => (item.id === assistantMessageId ? { ...item, streaming: false } : item)));
          },
        },
        controller.signal,
      );

      if (!receivedDelta) {
        setMessages((prev) => prev.map((item) => (item.id === assistantMessageId ? { ...item, streaming: false } : item)));
      }
    } catch (err) {
      if (controller.signal.aborted) {
        setMessages((prev) =>
          prev.map((item) => (item.id === assistantMessageId ? { ...item, text: "已取消本次生成，可以修改需求后重新发送。", streaming: false } : item)),
        );
        return;
      }

      try {
        const response = await sendChatMessage(text, "demo-session");
        setLastProducts(response.products || []);
        setMessages((prev) =>
          prev.map((message) =>
            message.id === assistantMessageId ? { ...message, text: response.answer, products: response.products, streaming: false } : message,
          ),
        );
      } catch {
        setError("接口暂时不可用，请确认后端服务已启动。当前会保留输入状态，方便重试。");
        setMessages((prev) => prev.map((item) => (item.id === assistantMessageId ? { ...item, streaming: false } : item)));
      }
    } finally {
      abortControllerRef.current = null;
      setLoading(false);
    }
  }

  function cancelStream() {
    abortControllerRef.current?.abort();
  }

  function addToCart(product: Product) {
    setCart((prev) => (prev.some((item) => item.id === product.id) ? prev : [...prev, product]));
    setToast("已加入购物车");
    setTimeout(() => setToast(""), 1800);
  }

  if (!started) {
    return (
      <SafeAreaView style={styles.safe}>
        <GradientBackdrop />
        <View style={styles.topBar}>
          <Ionicons name="menu" size={24} color={colors.onSurfaceVariant} />
          <Text style={styles.topTitle}>ShopPilot AI</Text>
          <View style={styles.avatar}><Ionicons name="person" size={16} color={colors.primary} /></View>
        </View>
        <View style={styles.heroWrap}>
          <View style={styles.logoGlow}>
            <LinearGradient colors={["#FFFFFFCC", "#F0DBFFCC"]} style={styles.logoBox}>
              <Ionicons name="sparkles" size={40} color={colors.primary} />
            </LinearGradient>
          </View>
          <Text style={styles.heroTitle}>ShopPilot AI</Text>
          <Text style={styles.heroSubtitle}>会聊天、懂商品、能帮你做购买决策</Text>
          <SearchBar value={input} onChange={setInput} onSend={() => submit()} />
          <View style={styles.quickGrid}>
            {quickPrompts.map((prompt, index) => (
              <Pressable style={styles.quickCard} key={prompt} onPress={() => submit(prompt)}>
                <Ionicons name={["headset-outline", "sunny-outline", "walk-outline"][index] as any} size={22} color={colors.primary} />
                <Text style={styles.quickText}>{prompt}</Text>
              </Pressable>
            ))}
          </View>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safe}>
      <GradientBackdrop />
      <KeyboardAvoidingView style={styles.flex} behavior={Platform.OS === "ios" ? "padding" : undefined}>
        <View style={styles.topBar}>
          <Pressable onPress={() => setStarted(false)}><Ionicons name="chevron-back" size={24} color={colors.onSurfaceVariant} /></Pressable>
          <View style={styles.brandRow}><Text style={styles.topTitle}>ShopPilot AI</Text><View style={styles.onlineDot} /></View>
          <Pressable style={styles.avatar} onPress={() => setCartOpen(true)}><Ionicons name="cart-outline" size={18} color={colors.primary} /><Text style={styles.cartBadge}>{cart.length}</Text></Pressable>
        </View>
        <ScrollView style={styles.chatList} contentContainerStyle={styles.chatContent} showsVerticalScrollIndicator={false}>
          {messages.length === 0 ? <EmptyState /> : null}
          {messages.map((message) => (
            <View key={message.id}>
              <ChatBubble role={message.role} text={message.text} streaming={message.streaming} />
              {message.products?.length ? (
                <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.productRail}>
                  {message.products.map((product) => <ProductCard key={product.id} product={product} onPress={() => setSelectedProduct(product)} onAdd={() => addToCart(product)} />)}
                </ScrollView>
              ) : null}
            </View>
          ))}
          {loading ? <ThinkingState /> : null}
          {error ? <ErrorState message={error} onRetry={lastPrompt ? () => submit(lastPrompt) : undefined} /> : null}
          {lastProducts.length ? (
            <View style={styles.actionStrip}>
              <Pressable style={styles.stripButton} onPress={() => setCompareOpen(true)}><Ionicons name="git-compare-outline" size={16} color={colors.primary} /><Text style={styles.stripText}>对比前两款</Text></Pressable>
              <Pressable style={styles.stripButton} onPress={() => submit("再便宜一点") }><Ionicons name="trending-down-outline" size={16} color={colors.primary} /><Text style={styles.stripText}>再便宜一点</Text></Pressable>
              <View style={styles.stripButton}><Ionicons name="logo-tiktok" size={16} color={colors.onSurface} /><Text style={styles.stripText}>{referenceCount} 条测评</Text></View>
            </View>
          ) : null}
        </ScrollView>
        <View style={styles.inputDock}>
          {loading ? (
            <Pressable style={styles.cancelButton} onPress={cancelStream}>
              <Ionicons name="stop-circle-outline" size={16} color={colors.primary} />
              <Text style={styles.cancelText}>停止生成</Text>
            </Pressable>
          ) : null}
          <SearchBar value={input} onChange={setInput} onSend={() => submit()} compact />
        </View>
      </KeyboardAvoidingView>
      {toast ? <View style={styles.toast}><Ionicons name="checkmark-circle" size={18} color={colors.white} /><Text style={styles.toastText}>{toast}</Text></View> : null}
      <ProductDetail product={selectedProduct} onClose={() => setSelectedProduct(null)} onAdd={(p) => addToCart(p)} />
      <CartDrawer visible={cartOpen} items={cart} onClose={() => setCartOpen(false)} onRemove={(id) => setCart((prev) => prev.filter((item) => item.id !== id))} />
      <ComparePanel visible={compareOpen} products={lastProducts} onClose={() => setCompareOpen(false)} />
    </SafeAreaView>
  );
}

function GradientBackdrop() {
  return (
    <View style={StyleSheet.absoluteFill}>
      <View style={styles.meshOne} />
      <View style={styles.meshTwo} />
    </View>
  );
}

function SearchBar({ value, onChange, onSend, compact = false }: { value: string; onChange: (value: string) => void; onSend: () => void; compact?: boolean }) {
  return (
    <View style={[styles.searchBar, compact && styles.searchBarCompact]}>
      <Ionicons name="search" size={20} color={colors.outline} />
      <TextInput style={styles.searchInput} placeholder="描述你想要寻找的商品或需求..." placeholderTextColor={colors.outline} value={value} onChangeText={onChange} onSubmitEditing={onSend} />
      <Pressable style={styles.sendButton} onPress={onSend}><Ionicons name="send" size={18} color={colors.white} /></Pressable>
    </View>
  );
}

function EmptyState() {
  return <View style={styles.emptyState}><Ionicons name="chatbubbles-outline" size={42} color={colors.primary} /><Text style={styles.emptyTitle}>今天想买点什么？</Text><Text style={styles.emptyCopy}>告诉我预算、场景、偏好或排除项，我会从本地商品库中推荐可信商品。</Text></View>;
}

function ThinkingState() {
  return <View style={styles.thinking}><ActivityIndicator color={colors.primary} /><Text style={styles.thinkingText}>ShopPilot AI 正在检索商品库...</Text></View>;
}

function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <View style={styles.errorBox}>
      <Ionicons name="alert-circle-outline" size={20} color={colors.error} />
      <Text style={styles.errorText}>{message}</Text>
      {onRetry ? <Pressable style={styles.retryButton} onPress={onRetry}><Text style={styles.retryText}>重试</Text></Pressable> : null}
    </View>
  );
}

function ProductDetail({ product, onClose, onAdd }: { product: Product | null; onClose: () => void; onAdd: (product: Product) => void }) {
  const [imageFailed, setImageFailed] = useState(false);
  const imageUri = getProductImageUri(product?.image_url);

  return (
    <Modal visible={!!product} transparent animationType="slide" onRequestClose={onClose}>
      <Pressable style={styles.detailScrim} onPress={onClose} />
      {product ? (
        <View style={styles.detailSheet}>
          <View style={styles.handle} />
          <View style={styles.detailHeader}><Text style={styles.detailTitle}>商品详情</Text><Pressable onPress={onClose}><Ionicons name="close" size={22} color={colors.onSurface} /></Pressable></View>
          <ScrollView showsVerticalScrollIndicator={false}>
            <View style={styles.detailHero}>
              {imageUri && !imageFailed ? (
                <Image source={{ uri: imageUri }} style={styles.detailImage} resizeMode="cover" onError={() => setImageFailed(true)} />
              ) : (
                <LinearGradient colors={["#E1E0FF", "#F0DBFF"]} style={styles.detailImageFallback}><Ionicons name="bag-handle-outline" size={52} color={colors.primary} /></LinearGradient>
              )}
            </View>
            <Text style={styles.detailName}>{product.name}</Text>
            <Text style={styles.detailPrice}>¥{product.price.toFixed(0)}</Text>
            <Text style={styles.detailDesc}>{product.description}</Text>
            {product.review_references?.length ? <Text style={styles.sectionTitle}>真实测评参考</Text> : null}
            {product.review_references?.map((ref) => <ReviewReferenceCard key={ref.url} reference={ref} />)}
            <Pressable style={styles.detailAdd} onPress={() => onAdd(product)}><Text style={styles.detailAddText}>加入购物车</Text></Pressable>
          </ScrollView>
        </View>
      ) : null}
    </Modal>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  safe: { backgroundColor: colors.background, flex: 1 },
  meshOne: { backgroundColor: "rgba(96,99,238,0.12)", borderRadius: 180, height: 280, left: -80, position: "absolute", top: 150, width: 280 },
  meshTwo: { backgroundColor: "rgba(156,72,234,0.12)", borderRadius: 180, height: 300, position: "absolute", right: -90, top: 40, width: 300 },
  topBar: { alignItems: "center", backgroundColor: "rgba(252,248,255,0.78)", borderBottomColor: "rgba(199,196,215,0.35)", borderBottomWidth: 1, flexDirection: "row", height: 64, justifyContent: "space-between", paddingHorizontal: spacing.md },
  topTitle: { color: colors.onSurface, fontSize: 22, fontWeight: "900" },
  brandRow: { alignItems: "center", flexDirection: "row", gap: spacing.xs },
  onlineDot: { backgroundColor: colors.success, borderRadius: radius.pill, height: 8, width: 8 },
  avatar: { alignItems: "center", backgroundColor: colors.surfaceHigh, borderRadius: radius.pill, height: 36, justifyContent: "center", minWidth: 36, paddingHorizontal: 8 },
  cartBadge: { color: colors.primary, fontSize: 10, fontWeight: "900", position: "absolute", right: 4, top: 2 },
  heroWrap: { alignItems: "center", flex: 1, justifyContent: "center", padding: spacing.lg },
  logoGlow: { borderRadius: radius.xl, marginBottom: spacing.md, ...shadow.glow },
  logoBox: { alignItems: "center", borderColor: "rgba(255,255,255,0.6)", borderRadius: radius.xl, borderWidth: 1, height: 88, justifyContent: "center", width: 88 },
  heroTitle: { color: colors.primary, fontSize: 46, fontWeight: "900", letterSpacing: -1.2 },
  heroSubtitle: { color: colors.onSurfaceVariant, fontSize: 18, lineHeight: 28, marginBottom: spacing.xl, marginTop: spacing.xs, textAlign: "center" },
  searchBar: { alignItems: "center", backgroundColor: "rgba(255,255,255,0.82)", borderColor: "rgba(255,255,255,0.6)", borderRadius: radius.pill, borderWidth: 1, flexDirection: "row", gap: spacing.xs, maxWidth: 680, padding: 8, width: "100%", ...shadow.card },
  searchBarCompact: { maxWidth: undefined },
  searchInput: { color: colors.onSurface, flex: 1, fontSize: 15, minHeight: 40, paddingHorizontal: spacing.xs },
  sendButton: { alignItems: "center", backgroundColor: colors.primary, borderRadius: radius.pill, height: 44, justifyContent: "center", width: 44 },
  quickGrid: { gap: spacing.sm, marginTop: spacing.xl, width: "100%" },
  quickCard: { alignItems: "center", backgroundColor: "rgba(255,255,255,0.78)", borderColor: "rgba(199,196,215,0.55)", borderRadius: radius.xl, borderWidth: 1, flexDirection: "row", gap: spacing.sm, padding: spacing.md, ...shadow.card },
  quickText: { color: colors.onSurface, flex: 1, fontSize: 14, fontWeight: "800" },
  chatList: { flex: 1 },
  chatContent: { paddingBottom: 128, paddingTop: spacing.md },
  productRail: { paddingLeft: spacing.md, paddingVertical: spacing.sm },
  inputDock: { backgroundColor: "rgba(252,248,255,0.92)", borderTopColor: "rgba(199,196,215,0.45)", borderTopWidth: 1, bottom: 0, left: 0, padding: spacing.md, position: "absolute", right: 0 },
  cancelButton: { alignItems: "center", alignSelf: "center", backgroundColor: colors.primary + "12", borderRadius: radius.pill, flexDirection: "row", gap: 5, marginBottom: spacing.xs, paddingHorizontal: spacing.sm, paddingVertical: 7 },
  cancelText: { color: colors.primary, fontSize: 12, fontWeight: "900" },
  emptyState: { alignItems: "center", backgroundColor: "rgba(255,255,255,0.78)", borderRadius: radius.xl, margin: spacing.md, padding: spacing.xl, ...shadow.card },
  emptyTitle: { color: colors.onSurface, fontSize: 22, fontWeight: "900", marginTop: spacing.sm },
  emptyCopy: { color: colors.onSurfaceVariant, fontSize: 14, lineHeight: 21, marginTop: spacing.xs, textAlign: "center" },
  thinking: { alignItems: "center", alignSelf: "flex-start", backgroundColor: "rgba(255,255,255,0.88)", borderRadius: radius.pill, flexDirection: "row", gap: spacing.sm, margin: spacing.md, paddingHorizontal: spacing.md, paddingVertical: spacing.sm, ...shadow.card },
  thinkingText: { color: colors.onSurfaceVariant, fontSize: 13, fontWeight: "700" },
  errorBox: { alignItems: "center", backgroundColor: colors.errorContainer, borderRadius: radius.lg, flexDirection: "row", gap: spacing.sm, margin: spacing.md, padding: spacing.md },
  errorText: { color: colors.error, flex: 1, fontSize: 13, fontWeight: "700" },
  retryButton: { backgroundColor: colors.white, borderRadius: radius.pill, paddingHorizontal: spacing.sm, paddingVertical: 7 },
  retryText: { color: colors.error, fontSize: 12, fontWeight: "900" },
  actionStrip: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs, paddingHorizontal: spacing.md, paddingVertical: spacing.sm },
  stripButton: { alignItems: "center", backgroundColor: "rgba(255,255,255,0.86)", borderRadius: radius.pill, flexDirection: "row", gap: 5, paddingHorizontal: spacing.sm, paddingVertical: 8 },
  stripText: { color: colors.onSurfaceVariant, fontSize: 12, fontWeight: "800" },
  toast: { alignItems: "center", alignSelf: "center", backgroundColor: colors.onSurface, borderRadius: radius.pill, bottom: 96, flexDirection: "row", gap: spacing.xs, paddingHorizontal: spacing.md, paddingVertical: spacing.sm, position: "absolute" },
  toastText: { color: colors.white, fontSize: 13, fontWeight: "900" },
  detailScrim: { ...StyleSheet.absoluteFill, backgroundColor: "rgba(27,27,35,0.28)" },
  detailSheet: { backgroundColor: colors.surface, borderTopLeftRadius: 28, borderTopRightRadius: 28, bottom: 0, left: 0, maxHeight: "88%", padding: spacing.md, position: "absolute", right: 0, ...shadow.card },
  handle: { alignSelf: "center", backgroundColor: colors.outlineVariant, borderRadius: radius.pill, height: 5, marginBottom: spacing.sm, width: 44 },
  detailHeader: { alignItems: "center", flexDirection: "row", justifyContent: "space-between", marginBottom: spacing.md },
  detailTitle: { color: colors.onSurface, fontSize: 24, fontWeight: "900" },
  detailHero: { backgroundColor: colors.surfaceContainer, borderRadius: radius.xl, height: 188, marginBottom: spacing.md, overflow: "hidden" },
  detailImage: { height: "100%", width: "100%" },
  detailImageFallback: { alignItems: "center", height: "100%", justifyContent: "center", width: "100%" },
  detailName: { color: colors.onSurface, fontSize: 20, fontWeight: "900", lineHeight: 27 },
  detailPrice: { color: colors.primary, fontSize: 28, fontWeight: "900", marginVertical: spacing.xs },
  detailDesc: { color: colors.onSurfaceVariant, fontSize: 14, lineHeight: 22, marginBottom: spacing.md },
  sectionTitle: { color: colors.onSurface, fontSize: 17, fontWeight: "900", marginBottom: spacing.sm, marginTop: spacing.sm },
  detailAdd: { alignItems: "center", backgroundColor: colors.primary, borderRadius: radius.pill, marginTop: spacing.md, paddingVertical: 15 },
  detailAddText: { color: colors.white, fontSize: 16, fontWeight: "900" },
});
