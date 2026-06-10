from typing import Optional
from pydantic import BaseModel, Field


class Sku(BaseModel):
    sku_id: str
    properties: dict[str, str] = Field(default_factory=dict)
    price: float


class ReviewReference(BaseModel):
    title: str
    url: str
    platform: str = "unknown"
    author: Optional[str] = None
    summary: Optional[str] = None


class Product(BaseModel):
    id: str
    name: str
    category: str
    sub_category: Optional[str] = None
    brand: Optional[str] = None
    price: float
    currency: str = "CNY"
    description: str = ""
    image_url: Optional[str] = None
    features: list[str] = Field(default_factory=list)
    tags: list[str] = Field(default_factory=list)
    skus: list[Sku] = Field(default_factory=list)
    review_references: list[ReviewReference] = Field(default_factory=list)
    source: str = "local_dataset"
    reason: Optional[str] = None
