import os
from typing import List, Optional
from pydantic import Field, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "FlashCart Supermarket API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"

    # MySQL 8 Single Primary Database Configuration
    # Does NOT hardcode credentials or secrets; reads dynamically from environment
    MYSQL_USER: str = Field(default_factory=lambda: os.getenv("MYSQL_USER", "flashcart"))
    MYSQL_PASSWORD: str = Field(default_factory=lambda: os.getenv("MYSQL_PASSWORD", ""))
    MYSQL_HOST: str = Field(default_factory=lambda: os.getenv("MYSQL_HOST", "localhost"))
    MYSQL_PORT: int = Field(default_factory=lambda: int(os.getenv("MYSQL_PORT", "3306")))
    MYSQL_DATABASE: str = Field(default_factory=lambda: os.getenv("MYSQL_DATABASE", "flashcart"))
    MYSQL_UNIX_SOCKET: Optional[str] = Field(default_factory=lambda: os.getenv("MYSQL_UNIX_SOCKET"))
    
    # Optional full database URL override (must be a MySQL connection string)
    DATABASE_URL: Optional[str] = Field(default_factory=lambda: os.getenv("DATABASE_URL"))

    @computed_field
    @property
    def sqlalchemy_database_url(self) -> str:
        """
        Generates authoritative MySQL connection string with PyMySQL driver.
        Enforces MySQL exclusively without SQLite fallback.
        """
        if self.DATABASE_URL:
            if not self.DATABASE_URL.startswith("mysql"):
                raise ValueError("DATABASE_URL must be a valid MySQL connection string starting with 'mysql+pymysql://' or 'mysql://'")
            return self.DATABASE_URL

        # Build connection URL from granular credentials
        user = self.MYSQL_USER
        password = self.MYSQL_PASSWORD
        auth = f"{user}:{password}" if password else user

        if self.MYSQL_UNIX_SOCKET:
            return f"mysql+pymysql://{auth}@localhost/{self.MYSQL_DATABASE}?unix_socket={self.MYSQL_UNIX_SOCKET}&charset=utf8mb4"

        return f"mysql+pymysql://{auth}@{self.MYSQL_HOST}:{self.MYSQL_PORT}/{self.MYSQL_DATABASE}?charset=utf8mb4"

    # JWT & Authentication Secret
    SECRET_KEY: str = Field(
        default_factory=lambda: os.getenv("SECRET_KEY", "flashcart-super-secure-production-jwt-secret-key-2026")
    )
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

    # Supermarket Configuration
    STORE_ID: str = "STORE_FLASHCART_001"
    STORE_NAME: str = "FlashCart"
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
