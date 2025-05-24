from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordRequestForm
from datetime import timedelta

from . import models, schemas, crud, database, auth, dependencies

# DB 테이블 생성
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "ReviewEat API 서버가 정상 작동 중입니다."}

@app.post("/register", response_model=schemas.UserResponse)
def register(user: schemas.UserCreate, db: Session = Depends(dependencies.get_db)):
    try:
        if crud.get_user_by_email(db, user.email):
            raise HTTPException(status_code=400, detail="이미 가입된 이메일입니다.")
        if crud.get_user_by_username(db, user.username):
            raise HTTPException(status_code=400, detail="이미 사용 중인 사용자 이름입니다.")
        created_user = crud.create_user(db, user)
        return created_user
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

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
    access_token_expires = timedelta(minutes=auth.config.settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.email},
        expires_delta=access_token_expires,
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/users/me", response_model=schemas.UserResponse)
def read_users_me(current_user: models.User = Depends(dependencies.get_current_user)):
    return current_user
