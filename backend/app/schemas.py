from pydantic import BaseModel, EmailStr, ConfigDict
from datetime import datetime
from typing import Optional, List

# --- User 관련 스키마 ---
class UserBase(BaseModel):
    email: EmailStr
    username: str

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(UserBase):
    id: int
    role: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

# --- Token 관련 스키마 ---
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class TokenData(BaseModel):
    email: Optional[str] = None

# --- 검색 기록 스키마 ---
class SearchHistoryBase(BaseModel):
    query: str
    is_place: bool = False
    name: Optional[str] = None

class SearchHistoryCreate(SearchHistoryBase):
    pass

class SearchHistoryResponse(SearchHistoryBase):
    id: int
    user_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

# --- 리뷰 관련 스키마 (Flutter 앱과 일치하도록 수정) ---
class ReviewCreate(BaseModel):
    place_name: str
    place_address: Optional[str] = None
    review_date: datetime  # visit_date -> review_date로 변경
    rating: str
    companion: Optional[str] = None
    review_text: str  # content -> review_text로 변경
    image_paths: Optional[str] = None  # 이미지 파일 경로들 (콤마로 구분)

class ReviewUpdate(BaseModel):
    place_name: Optional[str] = None
    place_address: Optional[str] = None
    review_date: Optional[datetime] = None  # visit_date -> review_date로 변경
    rating: Optional[str] = None
    companion: Optional[str] = None
    review_text: Optional[str] = None  # content -> review_text로 변경
    image_paths: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

class ReviewResponse(BaseModel):
    id: int
    user_id: int
    place_name: str
    place_address: Optional[str] = None
    review_date: datetime  # visit_date -> review_date로 변경
    rating: str
    companion: Optional[str] = None
    review_text: str  # content -> review_text로 변경
    image_paths: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

# --- 리뷰 생성 응답 스키마 ---
class ReviewCreateResponse(BaseModel):
    message: str
    review_id: str
    place_name: str
    rating: str
    image_count: int
    status: str
