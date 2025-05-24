from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordRequestForm
from datetime import timedelta
from typing import List, Optional
from pydantic import BaseModel

from . import models, schemas, crud, database, auth, dependencies

# DB 테이블 생성
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI()

# CORS 설정 추가
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 프로덕션에서는 구체적인 도메인 지정
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 검색 기록 요청 스키마
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

# 검색 기록 관련 API
@app.post("/search-history/", status_code=status.HTTP_201_CREATED)
def save_search_history(
    request: SearchHistoryRequest,
    current_user: models.User = Depends(dependencies.get_current_user),
    db: Session = Depends(dependencies.get_db)
):
    """검색 기록 저장 (일반 검색어와 특정 장소 구분)"""
    try:
        # 중복 기록 삭제
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
        
        # 새로운 검색 기록 저장
        search_record = models.SearchHistory(
            query=request.query,
            is_place=request.is_place,
            name=request.name if request.is_place else None,
            user_id=current_user.id
        )
        db.add(search_record)
        db.commit()
        db.refresh(search_record)
        
        return {
            "id": search_record.id,
            "query": search_record.query,
            "is_place": search_record.is_place,
            "name": search_record.name,
            "created_at": search_record.created_at,
            "message": "검색 기록이 저장되었습니다."
        }
    
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"검색 기록 저장 중 오류가 발생했습니다: {str(e)}"
        )

@app.get("/search-history/")
def get_search_history(
    limit: int = 10,
    current_user: models.User = Depends(dependencies.get_current_user),
    db: Session = Depends(dependencies.get_db)
):
    """사용자의 검색 기록 조회"""
    try:
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
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"검색 기록 조회 중 오류가 발생했습니다: {str(e)}"
        )

@app.delete("/search-history/{history_id}")
def delete_search_history(
    history_id: int,
    current_user: models.User = Depends(dependencies.get_current_user),
    db: Session = Depends(dependencies.get_db)
):
    """특정 검색 기록 삭제"""
    try:
        history = db.query(models.SearchHistory).filter(
            models.SearchHistory.id == history_id,
            models.SearchHistory.user_id == current_user.id
        ).first()
        
        if not history:
            raise HTTPException(status_code=404, detail="검색 기록을 찾을 수 없습니다.")
        
        db.delete(history)
        db.commit()
        
        return {"message": "검색 기록이 삭제되었습니다."}
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"검색 기록 삭제 중 오류가 발생했습니다: {str(e)}"
        )

@app.delete("/search-history/")
def clear_all_search_history(
    current_user: models.User = Depends(dependencies.get_current_user),
    db: Session = Depends(dependencies.get_db)
):
    """사용자의 모든 검색 기록 삭제"""
    try:
        deleted_count = db.query(models.SearchHistory).filter(
            models.SearchHistory.user_id == current_user.id
        ).delete()
        
        db.commit()
        
        return {"message": f"{deleted_count}개의 검색 기록이 삭제되었습니다."}
    
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"검색 기록 삭제 중 오류가 발생했습니다: {str(e)}"
        )

@app.get("/search-history/stats")
def get_search_history_stats(
    current_user: models.User = Depends(dependencies.get_current_user),
    db: Session = Depends(dependencies.get_db)
):
    """검색 기록 통계 조회"""
    try:
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
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"검색 기록 통계 조회 중 오류가 발생했습니다: {str(e)}"
        )
