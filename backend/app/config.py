import os
from pydantic_settings import BaseSettings
class Settings(BaseSettings):
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your_secret_key_here_change_this")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7일

settings = Settings()
