import os
from pydantic_settings import BaseSettings

# 환경설정 클래스 정의 (Pydantic 기반)
class Settings(BaseSettings):
    # JWT 서명에 사용할 비밀키 (환경변수에서 읽거나 기본값 사용)
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your_secret_key_here_change_this")
    # JWT 알고리즘 설정
    ALGORITHM: str = "HS256"
    # 액세스 토큰 만료 시간 (분 단위, 7일)
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7일

# 설정 객체 생성 (앱 전체에서 사용)
settings = Settings()