import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# 환경변수에서 DATABASE_URL 가져오기
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@db:5432/revieweat")

# PostgreSQL 엔진 생성
engine = create_engine(SQLALCHEMY_DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    """데이터베이스 세션 의존성"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def create_tables():
    """모든 테이블을 생성합니다."""
    from .models import User, SearchHistory
    Base.metadata.create_all(bind=engine)

def init_db():
    """데이터베이스 초기화 - 개발 환경에서 사용"""
    from .models import User, SearchHistory
    create_tables()
