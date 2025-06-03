from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from . import models, schemas
from passlib.context import CryptContext
from datetime import datetime
import asyncio
from typing import List, Optional

# 비밀번호 해싱을 위한 패스워드 컨텍스트 설정
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# ==================== 기존 동기 함수들 (호환성 유지) ====================

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

# ==================== 새로운 비동기 함수들 (코루틴 적용) ====================

# 비동기 사용자 조회
async def get_user_by_email_async(db: AsyncSession, email: str):
    """비동기 이메일 사용자 조회"""
    result = await db.execute(
        select(models.User).filter(models.User.email == email)
    )
    return result.scalar_one_or_none()

async def get_user_by_username_async(db: AsyncSession, username: str):
    """비동기 사용자명 사용자 조회"""
    result = await db.execute(
        select(models.User).filter(models.User.username == username)
    )
    return result.scalar_one_or_none()

# 비동기 사용자 생성 (병렬 중복 체크)
async def create_user_async(db: AsyncSession, user: schemas.UserCreate):
    """비동기 사용자 생성 - 이메일/사용자명 중복 체크를 병렬 처리"""
    
    # 병렬로 중복 체크
    email_check_task = asyncio.create_task(get_user_by_email_async(db, user.email))
    username_check_task = asyncio.create_task(get_user_by_username_async(db, user.username))
    
    # 결과 대기 (병렬 실행으로 성능 향상)
    existing_email_user, existing_username_user = await asyncio.gather(
        email_check_task,
        username_check_task
    )
    
    if existing_email_user:
        raise ValueError("이미 가입된 이메일입니다")
    if existing_username_user:
        raise ValueError("이미 사용 중인 사용자 이름입니다")
    
    # 비동기 사용자 생성
    hashed_password = pwd_context.hash(user.password)
    db_user = models.User(
        email=user.email,
        username=user.username,
        hashed_password=hashed_password
    )
    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)
    return db_user

# 비동기 리뷰 생성
async def create_review_async(db: AsyncSession, review_data: dict):
    """비동기 리뷰 생성"""
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
    await db.commit()
    await db.refresh(db_review)
    return db_review

# 비동기 리뷰 목록 조회 (필터링 포함)
async def get_reviews_by_user_async(db: AsyncSession, user_id: int, skip: int = 0, limit: int = 10):
    """비동기 사용자 리뷰 목록 조회"""
    result = await db.execute(
        select(models.Review)
        .filter(models.Review.user_id == user_id)
        .offset(skip)
        .limit(limit)
        .order_by(models.Review.created_at.desc())
    )
    return result.scalars().all()

# 비동기 리뷰 상세 정보 조회 (관련 데이터 병렬 로딩)
async def get_review_with_details_async(db: AsyncSession, review_id: int, user_id: int):
    """비동기 리뷰 상세 정보 조회 - 관련 데이터를 병렬로 로딩"""
    
    # 병렬로 데이터 조회
    review_task = asyncio.create_task(get_review_async(db, review_id, user_id))
    same_place_reviews_task = asyncio.create_task(get_same_place_reviews_async(db, review_id))
    
    # 결과 대기
    review, same_place_reviews = await asyncio.gather(
        review_task,
        same_place_reviews_task
    )
    
    return {
        'review': review,
        'same_place_reviews': same_place_reviews
    }

async def get_review_async(db: AsyncSession, review_id: int, user_id: int):
    """비동기 리뷰 단건 조회"""
    result = await db.execute(
        select(models.Review).filter(
            models.Review.id == review_id,
            models.Review.user_id == user_id
        )
    )
    return result.scalar_one_or_none()

async def get_same_place_reviews_async(db: AsyncSession, review_id: int):
    """비동기 같은 장소의 다른 리뷰들 조회"""
    # 먼저 해당 리뷰의 장소명 조회
    review_result = await db.execute(
        select(models.Review.place_name).filter(models.Review.id == review_id)
    )
    place_name = review_result.scalar_one_or_none()
    
    if not place_name:
        return []
    
    # 같은 장소의 다른 리뷰들 조회
    result = await db.execute(
        select(models.Review)
        .filter(
            models.Review.place_name == place_name,
            models.Review.id != review_id
        )
        .limit(5)
    )
    return result.scalars().all()

# 비동기 리뷰 업데이트
async def update_review_async(db: AsyncSession, review_id: int, review_update: schemas.ReviewUpdate, user_id: int):
    """비동기 리뷰 업데이트"""
    result = await db.execute(
        select(models.Review).filter(
            models.Review.id == review_id,
            models.Review.user_id == user_id
        )
    )
    review = result.scalar_one_or_none()
    
    if not review:
        return None
    
    update_data = review_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(review, key, value)
    
    await db.commit()
    await db.refresh(review)
    return review

# 비동기 리뷰 삭제
async def delete_review_async(db: AsyncSession, review_id: int, user_id: int):
    """비동기 리뷰 삭제"""
    result = await db.execute(
        select(models.Review).filter(
            models.Review.id == review_id,
            models.Review.user_id == user_id
        )
    )
    review = result.scalar_one_or_none()
    
    if not review:
        return False
    
    await db.delete(review)
    await db.commit()
    return True
