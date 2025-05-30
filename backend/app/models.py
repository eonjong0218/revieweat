from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from .database import Base

# User 모델: 사용자 정보 테이블
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)  
    email = Column(String, unique=True, index=True, nullable=False)  
    username = Column(String, unique=True, index=True, nullable=False) 
    hashed_password = Column(String, nullable=False) 
    role = Column(String, default="user")  
    created_at = Column(DateTime(timezone=True), server_default=func.now()) 

    # 사용자와 검색기록(1:N) 관계
    search_histories = relationship("SearchHistory", back_populates="user", cascade="all, delete-orphan")
    # 사용자와 리뷰(1:N) 관계
    reviews = relationship("Review", back_populates="user", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, username={self.username}, role={self.role})>"

# SearchHistory 모델: 검색 기록 테이블
class SearchHistory(Base):
    __tablename__ = "search_history"

    id = Column(Integer, primary_key=True, index=True)  
    query = Column(String, index=True, nullable=False)  
    is_place = Column(Boolean, default=False, nullable=False)  
    name = Column(String, index=True, nullable=True)  
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)  
    created_at = Column(DateTime(timezone=True), server_default=func.now()) 

    # 검색기록과 사용자(N:1) 관계
    user = relationship("User", back_populates="search_histories")

    def __repr__(self):
        return f"<SearchHistory(id={self.id}, query={self.query}, is_place={self.is_place}, name={self.name}, user_id={self.user_id})>"

# Review 모델: 리뷰 테이블
class Review(Base):
    __tablename__ = "reviews"

    id = Column(Integer, primary_key=True, index=True) 
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)  
    place_name = Column(String, nullable=False)  
    place_address = Column(String, nullable=True)  
    review_date = Column(DateTime, nullable=False) 
    rating = Column(String, nullable=False)  
    companion = Column(String, nullable=True)  
    review_text = Column(String, nullable=False)  
    image_paths = Column(String, nullable=True) 
    created_at = Column(DateTime(timezone=True), server_default=func.now())  

    # 리뷰와 사용자(N:1) 관계
    user = relationship("User", back_populates="reviews")

    def __repr__(self):
        return f"<Review(user_id={self.user_id}, place={self.place_name}, rating={self.rating})>"
