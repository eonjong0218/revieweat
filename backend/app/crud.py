from sqlalchemy.orm import Session
from . import models, schemas
from passlib.context import CryptContext
from datetime import datetime

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

def get_user_by_username(db: Session, username: str):
    return db.query(models.User).filter(models.User.username == username).first()

def create_user(db: Session, user: schemas.UserCreate):
    hashed_password = pwd_context.hash(user.password)
    db_user = models.User(email=user.email, username=user.username, hashed_password=hashed_password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

# --- 리뷰 CRUD 함수 (필드명 수정) ---

def create_review(db: Session, review_data: dict):
    """리뷰 생성 - 딕셔너리 형태의 데이터를 받아서 처리"""
    db_review = models.Review(
        user_id=review_data["user_id"],
        place_name=review_data["place_name"],
        place_address=review_data["place_address"],
        review_date=review_data["review_date"],  # visit_date -> review_date로 변경
        rating=review_data["rating"],
        companion=review_data["companion"],
        review_text=review_data["review_text"],  # content -> review_text로 변경
        image_paths=review_data["image_paths"]  # image_urls -> image_paths로 변경
    )
    db.add(db_review)
    db.commit()
    db.refresh(db_review)
    return db_review

def create_review_from_schema(db: Session, review: schemas.ReviewCreate, user_id: int):
    """스키마 객체를 사용한 리뷰 생성"""
    db_review = models.Review(
        user_id=user_id,
        place_name=review.place_name,
        place_address=review.place_address,
        review_date=review.review_date,  # visit_date -> review_date로 변경
        rating=review.rating,
        companion=review.companion,
        review_text=review.review_text,  # content -> review_text로 변경
        image_paths=review.image_paths  # image_urls -> image_paths로 변경
    )
    db.add(db_review)
    db.commit()
    db.refresh(db_review)
    return db_review

def get_reviews_by_user(db: Session, user_id: int, skip: int = 0, limit: int = 10):
    return db.query(models.Review).filter(models.Review.user_id == user_id).offset(skip).limit(limit).all()

def get_review(db: Session, review_id: int):
    return db.query(models.Review).filter(models.Review.id == review_id).first()

def get_review_by_user(db: Session, review_id: int, user_id: int):
    """특정 사용자의 리뷰만 조회 (권한 확인용)"""
    return db.query(models.Review).filter(
        models.Review.id == review_id,
        models.Review.user_id == user_id
    ).first()

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

def delete_review(db: Session, review_id: int, user_id: int = None):
    """리뷰 삭제 - 사용자 ID 확인 옵션"""
    query = db.query(models.Review).filter(models.Review.id == review_id)
    if user_id:
        query = query.filter(models.Review.user_id == user_id)
    
    review = query.first()
    if not review:
        return False
    db.delete(review)
    db.commit()
    return True

def get_reviews_by_place(db: Session, place_name: str, skip: int = 0, limit: int = 10):
    """특정 장소의 리뷰들 조회"""
    return db.query(models.Review).filter(
        models.Review.place_name == place_name
    ).offset(skip).limit(limit).all()

def get_user_review_count(db: Session, user_id: int):
    """사용자의 총 리뷰 개수"""
    return db.query(models.Review).filter(models.Review.user_id == user_id).count()
