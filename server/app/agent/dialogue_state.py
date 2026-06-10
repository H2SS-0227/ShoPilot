from typing import Optional
from pydantic import BaseModel, Field

from app.schemas.intent import Constraints


class DialogueState(BaseModel):
    session_id: str
    last_intent: Optional[str] = None
    last_constraints: dict = Field(default_factory=dict)
    last_recommended_products: list[str] = Field(default_factory=list)
    cart: list[dict] = Field(default_factory=list)


_STATES: dict[str, DialogueState] = {}


def get_dialogue_state(session_id: str) -> DialogueState:
    return _STATES.setdefault(session_id, DialogueState(session_id=session_id))


def merge_constraints(previous: dict, current: Constraints, message: str) -> Constraints:
    merged = Constraints(**previous) if previous else Constraints()
    data = current.model_dump()
    for key, value in data.items():
        if value not in (None, [], ""):
            setattr(merged, key, value)
    if ("再便宜" in message or "便宜点" in message) and merged.budget_max is not None:
        merged.budget_max = max(1, merged.budget_max * 0.8)
    return merged


def update_dialogue_state(session_id: str, intent: str, constraints: Constraints, product_ids: list[str]) -> DialogueState:
    state = get_dialogue_state(session_id)
    state.last_intent = intent
    state.last_constraints = constraints.model_dump()
    if product_ids:
        state.last_recommended_products = product_ids
    return state
