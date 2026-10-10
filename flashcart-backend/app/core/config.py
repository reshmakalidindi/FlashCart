import os
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "FlashCart Supermarket API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Database configuration: defaults to MySQL 8 with fallback option
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", 
        "mysql+pymysql://root:password@localhost:3306/flashcart"
    )
    # If MySQL is not reachable during local dev or tests, fallback to SQLite
    USE_SQLITE_FALLBACK: bool = True
    SQLITE_URL: str = "sqlite:///./flashcart.db"
    
    # JWT & Auth
    SECRET_KEY: str = os.getenv(
        "SECRET_KEY", 
        "flashcart-super-secure-production-jwt-secret-key-2026"
    )
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # Supermarket Configuration
    STORE_ID: str = "STORE_DMART_001"
    STORE_NAME: str = "D-Mart Express CyberCity"
    CURRENCY_SYMBOL: str = "₹"
    
    # CORS: Allow Flutter Web & Mobile clients
    CORS_ORIGINS: List[str] = ["*"]
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="allow",
    )


settings = Settings()
