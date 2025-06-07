from fastapi import FastAPI, Depends, HTTPException, status, File, UploadFile, Form, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordRequestForm
from datetime import timedelta, datetime
from typing import List, Optional
from pydantic import BaseModel
from sqlalchemy.exc import SQLAlchemyError
import os
import uuid

from . import models, schemas, crud, database, auth, dependencies

app = FastAPI()

# -------------------- [공통 설정 및 초기화] --------------------
# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 운영 환경에 맞게 변경 권장
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 정적 파일 서빙 설정
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# DB 테이블 생성 (앱 시작 시 한 번만)
@app.on_event("startup")
def on_startup():
    models.Base.metadata.create_all(bind=database.engine)

class SearchHistoryRequest(BaseModel):
    query: str
    is_place: bool = False
    name: Optional[str] = None

# -------------------- [루트 엔드포인트] --------------------
@app.get("/")
async def root():
    return {"message": "ReviewEat API 서버가 정상 작동 중입니다."}

# -------------------- [회원가입 기능] --------------------
@app.post("/register", response_model=schemas.UserResponse)
def register(user: schemas.UserCreate, db: Session = Depends(dependencies.get_db)):
    """
    회원가입 처리
    - 이메일/사용자명 중복 체크
    - 신규 사용자 생성
    """
    if crud.get_user_by_email(db, user.email):
        raise HTTPException(status_code=400, detail="이미 가입된 이메일입니다.")
    if crud.get_user_by_username(db, user.username):
        raise HTTPException(status_code=400, detail="이미 사용 중인 사용자 이름입니다.")
    created_user = crud.create_user(db, user)
    return created_user

# -------------------- [로그인 및 토큰 발급 기능] --------------------
@app.post("/token", response_model=schemas.Token)
def login_for_access_token(
    response: Response,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(dependencies.get_db),
):
    """
    로그인 및 JWT 토큰 발급
    - 이메일/비밀번호 검증
    - 토큰 만료 시간 설정
    - HTTP Only, Secure 쿠키 설정
    - 사용자 테이블에 세션 정보 저장
    """
    user = crud.get_user_by_email(db, form_data.username)
    if not user or not crud.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="이메일 또는 비밀번호가 올바르지 않습니다.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(
        minutes=auth.config.settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )
    access_token = auth.create_access_token(
        data={"sub": user.email},
        expires_delta=access_token_expires,
    )
    
    # 사용자 테이블에 세션 정보 저장 (HTTP Only, Secure 체크 확인용)
    try:
        user.session_token = access_token
        user.is_http_only = True  # ✓ 체크됨
        user.is_secure = True     # ✓ 체크됨
        user.session_expires_at = datetime.utcnow() + access_token_expires
        user.last_login_at = datetime.utcnow()
        
        db.commit()
        db.refresh(user)
    except Exception as e:
        db.rollback()
        print(f"세션 저장 오류: {e}")
    
    # HTTP Only, Secure 쿠키 설정 (보안 강화)
    response.set_cookie(
        key="access_token",
        value=access_token,
        httponly=True,      # JavaScript 접근 차단 (XSS 방지)
        secure=True,        # HTTPS에서만 전송 (도청 방지)
        samesite="strict",  # CSRF 공격 방지
        max_age=auth.config.settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        path="/"
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

# -------------------- [로그아웃 기능] --------------------
@app.post("/logout")
def logout(
    response: Response,
    current_user: models.User = Depends(dependencies.get_current_user),
    db: Session = Depends(dependencies.get_db)
):
    """
    로그아웃 처리
    - 쿠키 삭제
    - 사용자 테이블의 세션 무효화
    """
    # 현재 사용자의 세션 무효화
    try:
        current_user.session_token = None
        current_user.session_expires_at = None
        db.commit()
    except Exception as e:
        db.rollback()
        print(f"세션 무효화 오류: {e}")
    
    response.delete_cookie(
        key="access_token",
        httponly=True,
        secure=True,
        samesite="strict",
        path="/"
    )
    return {"message": "로그아웃되었습니다."}

# -------------------- [세션 상태 확인 기능] --------------------
@app.get("/session-status", response_model=schemas.SessionStatusResponse)
def get_session_status(
    current_user: models.User = Depends(dependencies.get_current_user),
    db: Session = Depends(dependencies.get_db)
):
    """현재 사용자의 세션 보안 설정 확인"""
    session_active = (
        current_user.session_token is not None and 
        current_user.session_expires_at is not None and 
        current_user.session_expires_at > datetime.utcnow()
    )
    
    return schemas.SessionStatusResponse(
        user_id=current_user.id,
        username=current_user.username,
        http_only_enabled=current_user.is_http_only,  # ✓ 체크 상태
        secure_enabled=current_user.is_secure,        # ✓ 체크 상태
        session_active=session_active,
        last_login_at=current_user.last_login_at,
        session_expires_at=current_user.session_expires_at
    )

# -------------------- [내 정보 조회 기능] --------------------
@app.get("/users/me", response_model=schemas.UserResponse)
def read_users_me(current_user: models.User = Depends(dependencies.get_current_user)):
    return current_user

# -------------------- [세션 정보 포함 사용자 정보 조회] --------------------
@app.get("/users/me/with-session", response_model=schemas.UserWithSessionResponse)
def read_users_me_with_session(current_user: models.User = Depends(dependencies.get_current_user)):
    """세션 정보를 포함한 사용자 정보 조회"""
    return current_user

# -------------------- [리뷰 작성 기능] --------------------
@app.post("/api/reviews", status_code=status.HTTP_201_CREATED)
async def create_review(
    place_name: str = Form(...),
    place_address: str = Form(...),
    review_date: str = Form(...),
    rating: str = Form(...),
    companion: str = Form(...),
    review_text: str = Form(...),
    images: List[UploadFile] = File(default=[]),
    current_user: models.User = Depends(dependencies.get_current_user),
    db: Session = Depends(dependencies.get_db)
):
    """
    리뷰 작성 및 이미지 업로드
    - 이미지 파일 저장
    - 리뷰 데이터 DB 저장
    """
    try:
        # 이미지 파일 저장
        image_paths = []
        if images:
            for image in images:
                if image.filename and image.filename.strip() and image.size > 0:
                    os.makedirs("uploads", exist_ok=True)
                    file_extension = os.path.splitext(image.filename)[1]
                    unique_filename = f"{uuid.uuid4()}{file_extension}"
                    file_path = f"uploads/{unique_filename}"
                    with open(file_path, "wb") as buffer:
                        content = await image.read()
                        buffer.write(content)
                    image_paths.append(file_path)
                    print(f"이미지 저장됨: {file_path}")
        
        # 리뷰 데이터 준비 및 DB 저장
        review_data = {
            "user_id": current_user.id,
            "place_name": place_name,
            "place_address": place_address,
            "review_date": datetime.fromisoformat(review_date.replace('Z', '+00:00')),
            "rating": rating,
            "companion": companion,
            "review_text": review_text,
            "image_paths": ",".join(image_paths) if image_paths else None,
            "created_at": datetime.utcnow()
        }
        
        saved_review = crud.create_review(db, review_data)
        return {
            "message": "리뷰가 성공적으로 저장되었습니다.",
            "review_id": saved_review.id,
            "place_name": place_name,
            "rating": rating,
            "image_count": len(image_paths),
            "image_paths": image_paths,
            "status": "success"
        }
    except Exception as e:
        print(f"리뷰 저장 오류: {str(e)}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"리뷰 저장 중 오류가 발생했습니다: {str(e)}"
        )

# -------------------- [검색 기록 저장 기능] --------------------
@app.post("/search-history/", status_code=status.HTTP_201_CREATED)
def save_search_history(
    request: SearchHistoryRequest,
    current_user: models.User = Depends(dependencies.get_current_user),
    db: Session = Depends(dependencies.get_db)
):
    """
    검색 기록 저장
    - 중복 검색 기록 삭제 후 저장
    - 장소/일반 검색 구분
    """
    if request.is_place and request.name:
        existing = db.query(models.SearchHistory).filter(
            models.SearchHistory.user_id == current_user.id,
            models.SearchHistory.is_place == True,
            models.SearchHistory.name == request.name
        ).first()
    else:
        existing = db.query(models.SearchHistory).filter(
            models.SearchHistory.user_id == current_user.id,
            models.SearchHistory.is_place == False,
            models.SearchHistory.query == request.query
        ).first()
    
    if existing:
        db.delete(existing)
    
    search_record = models.SearchHistory(
        query=request.query,
        is_place=request.is_place,
        name=request.name if request.is_place else None,
        user_id=current_user.id
    )
    
    try:
        db.add(search_record)
        db.commit()
        db.refresh(search_record)
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"검색 기록 저장 중 오류가 발생했습니다: {str(e)}"
        )
    
    return {
        "id": search_record.id,
        "query": search_record.query,
        "is_place": search_record.is_place,
        "name": search_record.name,
        "created_at": search_record.created_at,
        "message": "검색 기록이 저장되었습니다."
    }

# -------------------- [검색 기록 조회 기능] --------------------
@app.get("/search-history/")
def get_search_history(
    limit: int = 10,
    current_user: models.User = Depends(dependencies.get_current_user),
    db: Session = Depends(dependencies.get_db)
):
    """내 검색 기록 목록 조회"""
    history = db.query(models.SearchHistory).filter(
        models.SearchHistory.user_id == current_user.id
    ).order_by(
        models.SearchHistory.created_at.desc()
    ).limit(limit).all()
    
    return [
        {
            "id": record.id,
            "query": record.query,
            "is_place": record.is_place,
            "name": record.name,
            "created_at": record.created_at
        }
        for record in history
    ]

# -------------------- [검색 기록 삭제 기능] --------------------
@app.delete("/search-history/{history_id}")
def delete_search_history(
    history_id: int,
    current_user: models.User = Depends(dependencies.get_current_user),
    db: Session = Depends(dependencies.get_db)
):
    """특정 검색 기록 삭제"""
    history = db.query(models.SearchHistory).filter(
        models.SearchHistory.id == history_id,
        models.SearchHistory.user_id == current_user.id
    ).first()
    
    if not history:
        raise HTTPException(status_code=404, detail="검색 기록을 찾을 수 없습니다.")
    
    db.delete(history)
    db.commit()
    return {"message": "검색 기록이 삭제되었습니다."}

@app.delete("/search-history/")
def clear_all_search_history(
    current_user: models.User = Depends(dependencies.get_current_user),
    db: Session = Depends(dependencies.get_db)
):
    """전체 검색 기록 삭제"""
    deleted_count = db.query(models.SearchHistory).filter(
        models.SearchHistory.user_id == current_user.id
    ).delete()
    db.commit()
    return {"message": f"{deleted_count}개의 검색 기록이 삭제되었습니다."}

# -------------------- [세션 정리 기능] --------------------
@app.post("/cleanup-sessions")
def cleanup_expired_sessions(
    db: Session = Depends(dependencies.get_db)
):
    """만료된 세션 정리"""
    updated_count = db.query(models.User).filter(
        models.User.session_expires_at < datetime.utcnow()
    ).update({
        "session_token": None,
        "session_expires_at": None
    })
    db.commit()
    return {"message": f"{updated_count}개의 만료된 세션이 정리되었습니다."}

# -------------------- [프로필 및 리뷰 조회 기능] --------------------
@app.get("/profile")
def get_profile(
    current_user: models.User = Depends(dependencies.get_current_user)
):
    """사용자 프로필 정보 조회"""
    return {
        "id": current_user.id,
        "email": current_user.email,
        "username": current_user.username,
        "role": current_user.role,
        "created_at": current_user.created_at.isoformat() if current_user.created_at else None
    }

@app.get("/my-reviews")
def get_my_reviews(
    current_user: models.User = Depends(dependencies.get_current_user),
    db: Session = Depends(dependencies.get_db)
):
    """현재 로그인한 사용자의 리뷰 목록 조회"""
    reviews = db.query(models.Review).filter(
        models.Review.user_id == current_user.id
    ).order_by(
        models.Review.created_at.desc()
    ).all()
    
    # 날짜 형식을 문자열로 변환
    formatted_reviews = []
    for review in reviews:
        formatted_review = {
            "id": review.id,
            "user_id": review.user_id,
            "place_name": review.place_name,
            "place_address": review.place_address,
            "review_date": review.review_date.isoformat() if review.review_date else None,
            "rating": review.rating,
            "companion": review.companion,
            "review_text": review.review_text,
            "image_paths": review.image_paths,
            "created_at": review.created_at.isoformat() if review.created_at else None
        }
        formatted_reviews.append(formatted_review)
    
    return formatted_reviews
