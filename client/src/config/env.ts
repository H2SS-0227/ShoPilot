declare const process: { env?: Record<string, string | undefined> };

import { Platform } from "react-native";

const envApiBaseUrl = process.env?.EXPO_PUBLIC_API_BASE_URL;

function getDefaultApiBaseUrl() {
  if (Platform.OS === "web") {
    const host = globalThis.location?.hostname;
    if (host && host !== "localhost" && host !== "127.0.0.1") {
      return "";
    }
    return "http://127.0.0.1:8000";
  }

  if (Platform.OS === "android") {
    return "http://10.0.2.2:8000";
  }

  return "http://127.0.0.1:8000";
}

export const API_BASE_URL = envApiBaseUrl ?? getDefaultApiBaseUrl();
