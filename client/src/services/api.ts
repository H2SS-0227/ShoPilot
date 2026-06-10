import { API_BASE_URL } from "../config/env";
import type { ChatResponse, ChatStreamHandlers } from "../types/chat";

export async function sendChatMessage(message: string, sessionId = "demo-session"): Promise<ChatResponse> {
  const response = await fetch(`${API_BASE_URL}/api/chat`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ session_id: sessionId, message, stream: false }),
  });

  if (!response.ok) {
    throw new Error(`Chat API failed: ${response.status}`);
  }

  return response.json();
}

export async function streamChatMessage(
  message: string,
  sessionId = "demo-session",
  handlers: ChatStreamHandlers = {},
  signal?: AbortSignal,
): Promise<void> {
  const response = await fetch(`${API_BASE_URL}/api/chat`, {
    method: "POST",
    headers: { Accept: "text/event-stream", "Content-Type": "application/json" },
    body: JSON.stringify({ session_id: sessionId, message, stream: true }),
    signal,
  });

  if (!response.ok) {
    throw new Error(`Chat stream failed: ${response.status}`);
  }

  if (!response.body) {
    const fallback = await sendChatMessage(message, sessionId);
    handlers.onFinal?.(fallback);
    handlers.onDone?.();
    return;
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = "";

  while (true) {
    const { value, done } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const events = buffer.split(/\n\n/);
    buffer = events.pop() ?? "";

    for (const rawEvent of events) {
      dispatchSseEvent(rawEvent, handlers);
    }
  }

  if (buffer.trim()) {
    dispatchSseEvent(buffer, handlers);
  }
}

function dispatchSseEvent(rawEvent: string, handlers: ChatStreamHandlers) {
  const lines = rawEvent.split(/\r?\n/);
  const event = lines.find((line) => line.startsWith("event:"))?.slice("event:".length).trim();
  const dataText = lines
    .filter((line) => line.startsWith("data:"))
    .map((line) => line.slice("data:".length).trim())
    .join("\n");

  if (!event || !dataText) return;

  const data = JSON.parse(dataText);
  if (event === "meta") handlers.onMeta?.(data);
  if (event === "delta") handlers.onDelta?.(data.text ?? "");
  if (event === "final") handlers.onFinal?.(data);
  if (event === "done") handlers.onDone?.();
  if (event === "error") handlers.onError?.(data.message ?? "流式响应失败");
}
