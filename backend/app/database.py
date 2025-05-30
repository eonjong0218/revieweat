import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# 데이터베이스 접속 URL 환경변수에서 읽기 (없으면 기본값 사용)
SQLALCHEMY_DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "postgresql://postgres:postgres@db:5432/revieweat"
)

# SQLAlchemy 엔진 생성 (DB 연결 객체)
engine = create_engine(SQLALCHEMY_DATABASE_URL)

# 세션 팩토리 생성 (ORM 세션 관리)
SessionLocal = sessionmaker(
    autocommit=False, 
    autoflush=False, 
    bind=engine
)

# 베이스 클래스 (모든 ORM 모델의 부모)
Base = declarative_base()

def get_db():
    """FastAPI 의존성 주입용 DB 세션 생성 및 반환 (요청마다 새 세션)"""
    db = SessionLocal()
    try:
        yield db  # 세션 객체 반환
    finally:
        db.close()  # 요청 종료 시 세션 정리

def create_tables():
    """모든 테이블을 데이터베이스에 생성 (모델 import 필요)"""
    from .models import User, SearchHistory, Review  
    Base.metadata.create_all(bind=engine)

def init_db():
    """데이터베이스 초기화 함수 (개발 환경에서 테이블 생성 용도)"""
    from .models import User, SearchHistory, Review
    create_tables()