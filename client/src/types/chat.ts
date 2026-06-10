import type { Product } from "./product";

export type ChatMessage = {
  id: string;
  role: "user" | "assistant";
  text: string;
  products?: Product[];
  streaming?: boolean;
};

export type ComparisonRow = {
  dimension: string;
  items: Array<{ product_id: string; value: string }>;
};

export type CartAction = {
  action: string;
  product_id?: string | null;
  message?: string;
};

export type ChatResponse = {
  type: string;
  intent: string;
  answer: string;
  products: Product[];
  comparison: ComparisonRow[];
  cart_action?: CartAction;
  suggested_actions: string[];
};

export type ChatStreamEvent =
  | { event: "meta"; data: { session_id: string; intent?: string; created_at?: number } }
  | { event: "delta"; data: { text: string } }
  | { event: "final"; data: ChatResponse }
  | { event: "done"; data: { ok: boolean } }
  | { event: "error"; data: { message: string } };

export type ChatStreamHandlers = {
  onMeta?: (data: Extract<ChatStreamEvent, { event: "meta" }>["data"]) => void;
  onDelta?: (text: string) => void;
  onFinal?: (response: ChatResponse) => void;
  onDone?: () => void;
  onError?: (message: string) => void;
};
