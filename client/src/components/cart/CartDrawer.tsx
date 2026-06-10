import { Modal, Pressable, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import type { Product } from "../../types/product";
import { colors, radius, shadow, spacing } from "../../theme/tokens";

export function CartDrawer({ visible, items, onClose, onRemove }: { visible: boolean; items: Product[]; onClose: () => void; onRemove: (id: string) => void }) {
  const total = items.reduce((sum, item) => sum + item.price, 0);
  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <Pressable style={styles.scrim} onPress={onClose} />
      <View style={styles.drawer}>
        <View style={styles.handle} />
        <View style={styles.header}>
          <Text style={styles.title}>购物车</Text>
          <Pressable style={styles.close} onPress={onClose}><Ionicons name="close" size={22} color={colors.onSurface} /></Pressable>
        </View>
        {items.length === 0 ? (
          <View style={styles.empty}><Ionicons name="cart-outline" size={42} color={colors.outline} /><Text style={styles.emptyText}>购物车还是空的</Text></View>
        ) : items.map((item) => (
          <View key={item.id} style={styles.line}>
            <View style={styles.thumb}><Ionicons name="bag-handle-outline" size={20} color={colors.primary} /></View>
            <View style={{ flex: 1 }}>
              <Text style={styles.name} numberOfLines={1}>{item.name}</Text>
              <Text style={styles.price}>¥{item.price.toFixed(0)} · x1</Text>
            </View>
            <Pressable onPress={() => onRemove(item.id)}><Ionicons name="trash-outline" size={20} color={colors.error} /></Pressable>
          </View>
        ))}
        <View style={styles.footer}>
          <Text style={styles.total}>合计 ¥{total.toFixed(0)}</Text>
          <Pressable style={styles.checkout}><Text style={styles.checkoutText}>模拟确认下单</Text></Pressable>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  scrim: { ...StyleSheet.absoluteFill, backgroundColor: "rgba(27,27,35,0.28)" },
  drawer: { backgroundColor: colors.surface, borderTopLeftRadius: 28, borderTopRightRadius: 28, bottom: 0, left: 0, maxHeight: "78%", padding: spacing.md, position: "absolute", right: 0, ...shadow.card },
  handle: { alignSelf: "center", backgroundColor: colors.outlineVariant, borderRadius: radius.pill, height: 5, marginBottom: spacing.sm, width: 44 },
  header: { alignItems: "center", flexDirection: "row", justifyContent: "space-between", marginBottom: spacing.md },
  title: { color: colors.onSurface, fontSize: 24, fontWeight: "900" },
  close: { backgroundColor: colors.surfaceContainer, borderRadius: radius.pill, padding: 8 },
  empty: { alignItems: "center", gap: spacing.sm, padding: spacing.xl },
  emptyText: { color: colors.outline, fontSize: 15, fontWeight: "700" },
  line: { alignItems: "center", backgroundColor: colors.white, borderRadius: radius.lg, flexDirection: "row", gap: spacing.sm, marginBottom: spacing.sm, padding: spacing.sm },
  thumb: { alignItems: "center", backgroundColor: colors.primary + "14", borderRadius: radius.md, height: 44, justifyContent: "center", width: 44 },
  name: { color: colors.onSurface, fontSize: 14, fontWeight: "800" },
  price: { color: colors.primary, fontSize: 13, fontWeight: "800", marginTop: 2 },
  footer: { borderTopColor: colors.outlineVariant, borderTopWidth: 1, gap: spacing.sm, marginTop: spacing.md, paddingTop: spacing.md },
  total: { color: colors.onSurface, fontSize: 18, fontWeight: "900", textAlign: "right" },
  checkout: { alignItems: "center", backgroundColor: colors.primary, borderRadius: radius.pill, paddingVertical: 14 },
  checkoutText: { color: colors.white, fontSize: 16, fontWeight: "900" },
});
