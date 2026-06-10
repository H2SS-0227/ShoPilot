export type ReviewReference = {
  title: string;
  url: string;
  platform: string;
  author?: string;
  summary?: string;
};

export type Product = {
  id: string;
  name: string;
  category: string;
  sub_category?: string;
  brand?: string;
  price: number;
  currency: string;
  description: string;
  image_url?: string;
  features?: string[];
  tags?: string[];
  review_references?: ReviewReference[];
  reason?: string;
};
