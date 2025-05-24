from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from .database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="user")  # 기본값 user로 지정
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # 검색 기록과의 관계 설정
    search_histories = relationship("SearchHistory", back_populates="user", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, username={self.username}, role={self.role})>"

class SearchHistory(Base):
    __tablename__ = "search_history"

    id = Column(Integer, primary_key=True, index=True)
    query = Column(String, index=True, nullable=False)  # 검색어 (항상 저장)
    is_place = Column(Boolean, default=False, nullable=False)  # 특정 장소 여부
    name = Column(String, index=True, nullable=True)  # 장소명 (특정 장소인 경우에만)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # User와의 관계 설정
    user = relationship("User", back_populates="search_histories")

    def __repr__(self):
        return f"<SearchHistory(id={self.id}, query={self.query}, is_place={self.is_place}, name={self.name}, user_id={self.user_id})>"
