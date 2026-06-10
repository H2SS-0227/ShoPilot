from app.schemas.product import Product


def product_to_document(product: Product) -> str:
    sku_text = " ".join(
        f"{sku.sku_id} {' '.join(sku.properties.values())} 价格 {sku.price}"
        for sku in product.skus[:6]
    )
    return "\n".join(
        [
            f"商品名：{product.name}",
            f"品牌：{product.brand or ''}",
            f"类目：{product.category}/{product.sub_category or ''}",
            f"价格：{product.price}",
            f"描述：{product.description}",
            f"卖点：{'；'.join(product.features)}",
            f"标签：{', '.join(product.tags)}",
            f"SKU：{sku_text}",
        ]
    )
