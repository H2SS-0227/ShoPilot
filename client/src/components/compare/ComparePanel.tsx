import { Modal, Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import type { Product } from "../../types/product";
import { colors, radius, shadow, spacing } from "../../theme/tokens";

export function ComparePanel({ visible, products, onClose }: { visible: boolean; products: Product[]; onClose: () => void }) {
  const pair = products.slice(0, 2);
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <View style={styles.scrim}>
        <View style={styles.panel}>
          <View style={styles.header}>
            <Text style={styles.title}>商品对比</Text>
            <Pressable onPress={onClose}><Ionicons name="close" size={22} color={colors.onSurface} /></Pressable>
          </View>
          <ScrollView showsVerticalScrollIndicator={false}>
            <View style={styles.columns}>
              {pair.map((product) => (
                <View style={styles.product} key={product.id}>
                  <View style={styles.icon}><Ionicons name="cube-outline" size={22} color={colors.primary} /></View>
                  <Text style={styles.productName} numberOfLines={2}>{product.name}</Text>
                  <Text style={styles.price}>¥{product.price.toFixed(0)}</Text>
                </View>
              ))}
            </View>
            {["价格", "类目", "推荐理由", "测评参考"].map((dim) => (
              <View style={styles.row} key={dim}>
                <Text style={styles.dim}>{dim}</Text>
                <View style={styles.values}>
                  {pair.map((product) => (
                    <Text style={styles.value} key={`${dim}-${product.id}`} numberOfLines={3}>
                      {dim === "价格" ? `¥${product.price.toFixed(0)}` : dim === "类目" ? product.sub_category || product.category : dim === "测评参考" ? `${product.review_references?.length || 0} 条` : product.reason || "基于商品库匹配"}
                    </Text>
                  ))}
                </View>
              </View>
            ))}
            <View style={styles.conclusion}>
              <Ionicons name="sparkles-outline" size={18} color={colors.secondary} />
              <Text style={styles.conclusionText}>建议优先选择更贴合预算、场景和真实测评参考更充分的商品。</Text>
            </View>
          </ScrollView>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  scrim: { alignItems: "center", backgroundColor: "rgba(27,27,35,0.28)", flex: 1, justifyContent: "center", padding: spacing.md },
  panel: { backgroundColor: colors.surface, borderRadius: 28, maxHeight: "82%", padding: spacing.md, width: "100%", ...shadow.card },
  header: { alignItems: "center", flexDirection: "row", justifyContent: "space-between", marginBottom: spacing.md },
  title: { color: colors.onSurface, fontSize: 24, fontWeight: "900" },
  columns: { flexDirection: "row", gap: spacing.sm, marginBottom: spacing.md },
  product: { backgroundColor: colors.white, borderRadius: radius.lg, flex: 1, gap: 6, padding: spacing.sm },
  icon: { alignItems: "center", backgroundColor: colors.primary + "14", borderRadius: radius.md, height: 42, justifyContent: "center", width: 42 },
  productName: { color: colors.onSurface, fontSize: 13, fontWeight: "800", minHeight: 36 },
  price: { color: colors.primary, fontSize: 18, fontWeight: "900" },
  row: { backgroundColor: "rgba(255,255,255,0.78)", borderRadius: radius.lg, marginBottom: spacing.sm, padding: spacing.sm },
  dim: { color: colors.secondary, fontSize: 13, fontWeight: "900", marginBottom: 6 },
  values: { flexDirection: "row", gap: spacing.sm },
  value: { color: colors.onSurfaceVariant, flex: 1, fontSize: 12, lineHeight: 17 },
  conclusion: { alignItems: "center", backgroundColor: colors.secondary + "12", borderRadius: radius.lg, flexDirection: "row", gap: spacing.sm, marginTop: spacing.sm, padding: spacing.md },
  conclusionText: { color: colors.onSurface, flex: 1, fontSize: 13, fontWeight: "700", lineHeight: 19 },
});
