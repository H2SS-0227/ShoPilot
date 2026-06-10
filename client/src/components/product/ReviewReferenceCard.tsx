import { Linking, Pressable, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import type { ReviewReference } from "../../types/product";
import { colors, radius, shadow, spacing } from "../../theme/tokens";

export function ReviewReferenceCard({ reference, compact = false }: { reference: ReviewReference; compact?: boolean }) {
  return (
    <Pressable style={[styles.card, compact && styles.compact]} onPress={() => Linking.openURL(reference.url)}>
      <View style={styles.iconBadge}>
        <Ionicons name="logo-tiktok" size={16} color={colors.white} />
      </View>
      <View style={styles.body}>
        <View style={styles.headerRow}>
          <Text style={styles.platform}>{reference.platform || "TikTok"}</Text>
          <Text style={styles.hint}>真实测评参考</Text>
        </View>
        <Text style={styles.title} numberOfLines={compact ? 1 : 2}>{reference.title}</Text>
        {reference.summary ? <Text style={styles.summary} numberOfLines={compact ? 1 : 3}>{reference.summary}</Text> : null}
        {reference.author ? <Text style={styles.author}>@{reference.author}</Text> : null}
      </View>
      <Ionicons name="open-outline" size={18} color={colors.primary} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.88)",
    borderColor: "rgba(199,196,215,0.65)",
    borderRadius: radius.lg,
    borderWidth: 1,
    flexDirection: "row",
    gap: spacing.sm,
    padding: spacing.md,
    ...shadow.card,
  },
  compact: {
    padding: spacing.sm,
  },
  iconBadge: {
    alignItems: "center",
    backgroundColor: colors.onSurface,
    borderRadius: radius.pill,
    height: 32,
    justifyContent: "center",
    width: 32,
  },
  body: { flex: 1, gap: 2 },
  headerRow: { alignItems: "center", flexDirection: "row", gap: spacing.xs },
  platform: { color: colors.primary, fontSize: 12, fontWeight: "800" },
  hint: { color: colors.outline, fontSize: 11, fontWeight: "600" },
  title: { color: colors.onSurface, fontSize: 13, fontWeight: "800" },
  summary: { color: colors.onSurfaceVariant, fontSize: 12, lineHeight: 17 },
  author: { color: colors.secondary, fontSize: 12, fontWeight: "700" },
});
