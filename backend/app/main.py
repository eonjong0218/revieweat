from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from jose import JWTError, jwt
from datetime import datetime, timedelta
from pydantic import BaseModel
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# 절대 경로 import
from models import Base, User
from crud import get_user_by_email, verify_password

DATABASE_URL = os.getenv("DATABASE_URL")
SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# DB 세션 연결
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base.metadata.create_all(bind=engine)

app = FastAPI()

# CORS 설정
origins = ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic 모델
class Token(BaseModel):
    access_token: str
    token_type: str

class LoginInput(BaseModel):
    email: str
    password: str

# DB 세션 의존성
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# JWT 토큰 생성 함수
def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# 로그인 라우터
@app.post("/login", response_model=Token)
def login_user(login_input: LoginInput, db: Session = Depends(get_db)):
    try:
        user = get_user_by_email(db, login_input.email)
        if not user or not verify_password(login_input.password, user.password):
            raise HTTPException(status_code=400, detail="Invalid email or password")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    access_token = create_access_token(data={"sub": user.email, "user_id": user.id, "role": user.role})
    return {"access_token": access_token, "token_type": "bearer"}
