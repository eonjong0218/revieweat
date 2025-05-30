from sqlalchemy.orm import Session
from . import models, schemas
from passlib.context import CryptContext
from datetime import datetime

# 비밀번호 해싱을 위한 패스워드 컨텍스트 설정
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# -------------------- 사용자 관련 함수 --------------------

# 이메일로 사용자 조회
def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

# 사용자명으로 사용자 조회
def get_user_by_username(db: Session, username: str):
    return db.query(models.User).filter(models.User.username == username).first()

# 신규 사용자 생성 (비밀번호 해싱 포함)
def create_user(db: Session, user: schemas.UserCreate):
    hashed_password = pwd_context.hash(user.password)
    db_user = models.User(
        email=user.email,
        username=user.username,
        hashed_password=hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# 비밀번호 검증 (평문 vs 해시)
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

# -------------------- 리뷰 관련 CRUD 함수 --------------------

# 리뷰 생성 - 딕셔너리 데이터 입력
def create_review(db: Session, review_data: dict):
    db_review = models.Review(
        user_id=review_data["user_id"],
        place_name=review_data["place_name"],
        place_address=review_data["place_address"],
        review_date=review_data["review_date"],
        rating=review_data["rating"],
        companion=review_data["companion"],
        review_text=review_data["review_text"],
        image_paths=review_data["image_paths"]
    )
    db.add(db_review)
    db.commit()
    db.refresh(db_review)
    return db_review

# 리뷰 생성 - 스키마 객체 입력
def create_review_from_schema(db: Session, review: schemas.ReviewCreate, user_id: int):
    db_review = models.Review(
        user_id=user_id,
        place_name=review.place_name,
        place_address=review.place_address,
        review_date=review.review_date,
        rating=review.rating,
        companion=review.companion,
        review_text=review.review_text,
        image_paths=review.image_paths
    )
    db.add(db_review)
    db.commit()
    db.refresh(db_review)
    return db_review

# 특정 사용자의 리뷰 목록 조회 (페이징)
def get_reviews_by_user(db: Session, user_id: int, skip: int = 0, limit: int = 10):
    return db.query(models.Review).filter(
        models.Review.user_id == user_id
    ).offset(skip).limit(limit).all()

# 리뷰 ID로 리뷰 단건 조회
def get_review(db: Session, review_id: int):
    return db.query(models.Review).filter(models.Review.id == review_id).first()

# 특정 사용자의 특정 리뷰 조회 (권한 확인용)
def get_review_by_user(db: Session, review_id: int, user_id: int):
    return db.query(models.Review).filter(
        models.Review.id == review_id,
        models.Review.user_id == user_id
    ).first()

# 리뷰 수정 (입력값만 변경)
def update_review(db: Session, review_id: int, review_update: schemas.ReviewUpdate):
    review = db.query(models.Review).filter(models.Review.id == review_id).first()
    if not review:
        return None
    update_data = review_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(review, key, value)
    db.commit()
    db.refresh(review)
    return review

# 리뷰 삭제 (user_id 전달 시 본인 리뷰만 삭제)
def delete_review(db: Session, review_id: int, user_id: int = None):
    query = db.query(models.Review).filter(models.Review.id == review_id)
    if user_id:
        query = query.filter(models.Review.user_id == user_id)
    review = query.first()
    if not review:
        return False
    db.delete(review)
    db.commit()
    return True

# 특정 장소의 리뷰 목록 조회 (페이징)
def get_reviews_by_place(db: Session, place_name: str, skip: int = 0, limit: int = 10):
    return db.query(models.Review).filter(
        models.Review.place_name == place_name
    ).offset(skip).limit(limit).all()

# 사용자의 총 리뷰 개수 반환
def get_user_review_count(db: Session, user_id: int):
    return db.query(models.Review).filter(models.Review.user_id == user_id).count()
