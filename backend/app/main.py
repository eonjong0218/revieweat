from fastapi import FastAPI, Depends, HTTPException, status, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
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

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 운영 환경에 맞게 변경 권장
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# DB 테이블 생성 (앱 시작 시 한 번만)
@app.on_event("startup")
def on_startup():
    models.Base.metadata.create_all(bind=database.engine)

class SearchHistoryRequest(BaseModel):
    query: str
    is_place: bool = False
    name: Optional[str] = None

@app.get("/")
async def root():
    return {"message": "ReviewEat API 서버가 정상 작동 중입니다."}

@app.post("/register", response_model=schemas.UserResponse)
def register(user: schemas.UserCreate, db: Session = Depends(dependencies.get_db)):
    if crud.get_user_by_email(db, user.email):
        raise HTTPException(status_code=400, detail="이미 가입된 이메일입니다.")
    if crud.get_user_by_username(db, user.username):
        raise HTTPException(status_code=400, detail="이미 사용 중인 사용자 이름입니다.")
    
    created_user = crud.create_user(db, user)
    return created_user

@app.post("/token", response_model=schemas.Token)
def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(dependencies.get_db),
):
    # OAuth2PasswordRequestForm 기본 필드명 username이 email 역할
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
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/users/me", response_model=schemas.UserResponse)
def read_users_me(current_user: models.User = Depends(dependencies.get_current_user)):
    return current_user

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
    try:
        # 이미지 파일 저장 (수정된 로직)
        image_paths = []
        
        # 이미지가 있는지 확인하는 조건 수정
        if images:
            for image in images:
                # 파일명이 있고 실제 파일 크기가 0보다 큰 경우만 처리
                if image.filename and image.filename.strip() and image.size > 0:
                    # uploads 디렉토리 생성
                    os.makedirs("uploads", exist_ok=True)
                    
                    # 고유한 파일명 생성
                    file_extension = os.path.splitext(image.filename)[1]
                    unique_filename = f"{uuid.uuid4()}{file_extension}"
                    file_path = f"uploads/{unique_filename}"
                    
                    # 파일 저장
                    with open(file_path, "wb") as buffer:
                        content = await image.read()
                        buffer.write(content)
                    
                    image_paths.append(file_path)
                    print(f"이미지 저장됨: {file_path}")
        
        print(f"처리된 이미지 개수: {len(image_paths)}")
        print(f"이미지 경로들: {image_paths}")
        
        # 리뷰 데이터 준비
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
        
        print(f"리뷰 데이터 수신: {review_data}")
        
        # 실제 데이터베이스에 저장
        saved_review = crud.create_review(db, review_data)
        
        return {
            "message": "리뷰가 성공적으로 저장되었습니다.",
            "review_id": saved_review.id,
            "place_name": place_name,
            "rating": rating,
            "image_count": len(image_paths),
            "image_paths": image_paths,  # 디버깅용 추가
            "status": "success"
        }
        
    except Exception as e:
        print(f"리뷰 저장 오류: {str(e)}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"리뷰 저장 중 오류가 발생했습니다: {str(e)}"
        )

@app.post("/search-history/", status_code=status.HTTP_201_CREATED)
def save_search_history(
    request: SearchHistoryRequest,
    current_user: models.User = Depends(dependencies.get_current_user),
    db: Session = Depends(dependencies.get_db)
):
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

@app.get("/search-history/")
def get_search_history(
    limit: int = 10,
    current_user: models.User = Depends(dependencies.get_current_user),
    db: Session = Depends(dependencies.get_db)
):
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

@app.delete("/search-history/{history_id}")
def delete_search_history(
    history_id: int,
    current_user: models.User = Depends(dependencies.get_current_user),
    db: Session = Depends(dependencies.get_db)
):
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
    deleted_count = db.query(models.SearchHistory).filter(
        models.SearchHistory.user_id == current_user.id
    ).delete()
    
    db.commit()
    
    return {"message": f"{deleted_count}개의 검색 기록이 삭제되었습니다."}

@app.get("/search-history/stats")
def get_search_history_stats(
    current_user: models.User = Depends(dependencies.get_current_user),
    db: Session = Depends(dependencies.get_db)
):
    total_searches = db.query(models.SearchHistory).filter(
        models.SearchHistory.user_id == current_user.id
    ).count()
    
    place_searches = db.query(models.SearchHistory).filter(
        models.SearchHistory.user_id == current_user.id,
        models.SearchHistory.is_place == True
    ).count()
    
    query_searches = total_searches - place_searches
    
    return {
        "total_searches": total_searches,
        "place_searches": place_searches,
        "query_searches": query_searches
    }
