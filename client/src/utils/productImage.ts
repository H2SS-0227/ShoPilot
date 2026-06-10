import { API_BASE_URL } from "../config/env";

function encodePath(path: string) {
  return path
    .split("/")
    .map((segment) => (segment ? encodeURIComponent(segment) : segment))
    .join("/");
}

export function getProductImageUri(imageUrl?: string) {
  if (!imageUrl) {
    return undefined;
  }

  if (imageUrl.startsWith("http://") || imageUrl.startsWith("https://")) {
    return imageUrl;
  }

  const datasetMarker = "ecommerce_agent_dataset/";
  const normalizedPath = imageUrl.includes(datasetMarker)
    ? `/assets/products/${imageUrl.split(datasetMarker)[1]}`
    : imageUrl;

  if (normalizedPath.startsWith("/")) {
    return `${API_BASE_URL}${encodePath(normalizedPath)}`;
  }

  return `${API_BASE_URL}/${encodePath(normalizedPath)}`;
}
