from typing import Optional
from functools import lru_cache
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file="server/.env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "ShopPilot AI"
    app_env: str = "local"
    dataset_root: str = "ecommerce_agent_dataset"
    normalized_products_path: str = "server/data/normalized/products.json"
    rag_index_dir: str = "server/data/indexes"
    retriever_backend: str = "tfidf"
    llm_provider: str = "volcengine_ark"
    llm_api_base: Optional[str] = "https://ark.cn-beijing.volces.com/api/v3/"
    llm_api_key: Optional[str] = Field(default=None, repr=False)
    llm_model: Optional[str] = "ep-20260514111645-lmgt2"
    llm_model_name: Optional[str] = "Doubao-Seed-2.0-lite"
    enable_llm: bool = True
    enable_sse: bool = True


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
