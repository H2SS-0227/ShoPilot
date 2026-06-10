from typing import Optional
from pydantic import BaseModel, Field


class Constraints(BaseModel):
    category: Optional[str] = None
    budget_min: Optional[float] = None
    budget_max: Optional[float] = None
    brand_preferences: list[str] = Field(default_factory=list)
    preferences: list[str] = Field(default_factory=list)
    exclusions: list[str] = Field(default_factory=list)
    scenario: Optional[str] = None
    target_user: Optional[str] = None
    referenced_product_position: Optional[int] = None
    compare_targets: list[str] = Field(default_factory=list)
