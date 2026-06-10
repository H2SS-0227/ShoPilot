import { StyleSheet, Text, View } from "react-native";
import { colors, radius, shadow, spacing } from "../../theme/tokens";

export function ChatBubble({ role, text, streaming = false }: { role: "user" | "assistant"; text: string; streaming?: boolean }) {
  const isUser = role === "user";
  return (
    <View style={[styles.row, isUser && styles.userRow]}>
      <View style={[styles.bubble, isUser ? styles.userBubble : styles.assistantBubble]}>
        <Text style={[styles.text, isUser && styles.userText]}>
          {text}
          {streaming ? <Text style={styles.cursor}>▍</Text> : null}
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: "row", marginVertical: 6, paddingHorizontal: spacing.md },
  userRow: { justifyContent: "flex-end" },
  bubble: { borderRadius: radius.xl, maxWidth: "84%", paddingHorizontal: spacing.md, paddingVertical: spacing.sm },
  assistantBubble: { backgroundColor: "rgba(255,255,255,0.9)", borderBottomLeftRadius: 6, ...shadow.card },
  userBubble: { backgroundColor: colors.primary, borderBottomRightRadius: 6 },
  text: { color: colors.onSurface, fontSize: 15, lineHeight: 22 },
  cursor: { color: colors.primary, fontWeight: "900" },
  userText: { color: colors.white, fontWeight: "600" },
});
