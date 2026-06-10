import { Image, Pressable, StyleSheet, Text, View } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons } from "@expo/vector-icons";
import { useState } from "react";
import type { Product } from "../../types/product";
import { colors, radius, shadow, spacing } from "../../theme/tokens";
import { getProductImageUri } from "../../utils/productImage";

export function ProductCard({ product, onPress, onAdd }: { product: Product; onPress?: () => void; onAdd?: () => void }) {
  const refs = product.review_references ?? [];
  const [imageFailed, setImageFailed] = useState(false);
  const imageUri = getProductImageUri(product.image_url);
  return (
    <Pressable style={styles.card} onPress={onPress}>
      <View style={styles.imageFrame}>
        {imageUri && !imageFailed ? (
          <Image source={{ uri: imageUri }} style={styles.image} resizeMode="cover" onError={() => setImageFailed(true)} />
        ) : (
          <LinearGradient colors={["#E1E0FF", "#F0DBFF"]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.imageMock}>
            <Ionicons name="bag-handle-outline" size={30} color={colors.primary} />
          </LinearGradient>
        )}
      </View>
      <View style={styles.content}>
        <View style={styles.tagRow}>
          <Text style={styles.tag}>{product.sub_category || product.category}</Text>
          {refs.length > 0 ? <Text style={styles.reviewTag}>TikTok 测评</Text> : null}
        </View>
        <Text style={styles.name} numberOfLines={2}>{product.name}</Text>
        <Text style={styles.price}>¥{product.price.toFixed(0)}</Text>
        {product.reason ? <Text style={styles.reason} numberOfLines={3}>{product.reason}</Text> : null}
        {refs[0] ? (
          <View style={styles.reviewLine}>
            <Ionicons name="logo-tiktok" size={14} color={colors.onSurface} />
            <Text style={styles.reviewText} numberOfLines={1}>来自 @{refs[0].author || "TikTok"} 的真实测评参考</Text>
          </View>
        ) : null}
        <View style={styles.actions}>
          <Pressable style={styles.secondaryButton} onPress={onPress}>
            <Text style={styles.secondaryText}>查看详情</Text>
          </Pressable>
          <Pressable style={styles.primaryButton} onPress={onAdd}>
            <Ionicons name="cart-outline" size={16} color={colors.white} />
            <Text style={styles.primaryText}>加入</Text>
          </Pressable>
        </View>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: "rgba(255,255,255,0.88)",
    borderColor: "rgba(199,196,215,0.6)",
    borderRadius: radius.xl,
    borderWidth: 1,
    flexDirection: "row",
    gap: spacing.md,
    marginRight: spacing.md,
    padding: spacing.md,
    width: 312,
    ...shadow.card,
  },
  imageMock: {
    alignItems: "center",
    height: "100%",
    justifyContent: "center",
    width: "100%",
  },
  imageFrame: {
    backgroundColor: colors.surfaceContainer,
    borderRadius: radius.lg,
    height: 116,
    overflow: "hidden",
    width: 92,
  },
  image: {
    height: "100%",
    width: "100%",
  },
  content: { flex: 1, gap: 6 },
  tagRow: { flexDirection: "row", gap: 6 },
  tag: { backgroundColor: colors.primary + "18", borderRadius: radius.pill, color: colors.primary, fontSize: 11, fontWeight: "800", paddingHorizontal: 8, paddingVertical: 3 },
  reviewTag: { backgroundColor: colors.onSurface + "12", borderRadius: radius.pill, color: colors.onSurface, fontSize: 11, fontWeight: "800", paddingHorizontal: 8, paddingVertical: 3 },
  name: { color: colors.onSurface, fontSize: 15, fontWeight: "800", lineHeight: 20 },
  price: { color: colors.primary, fontSize: 20, fontWeight: "900" },
  reason: { color: colors.onSurfaceVariant, fontSize: 12, lineHeight: 17 },
  reviewLine: { alignItems: "center", flexDirection: "row", gap: 5 },
  reviewText: { color: colors.onSurfaceVariant, flex: 1, fontSize: 11, fontWeight: "600" },
  actions: { flexDirection: "row", gap: spacing.xs, marginTop: 2 },
  secondaryButton: { alignItems: "center", backgroundColor: colors.surfaceContainer, borderRadius: radius.pill, flex: 1, paddingVertical: 8 },
  secondaryText: { color: colors.onSurfaceVariant, fontSize: 12, fontWeight: "800" },
  primaryButton: { alignItems: "center", backgroundColor: colors.primary, borderRadius: radius.pill, flexDirection: "row", gap: 4, justifyContent: "center", paddingHorizontal: 12, paddingVertical: 8 },
  primaryText: { color: colors.white, fontSize: 12, fontWeight: "900" },
});
