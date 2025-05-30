from datetime import datetime, timedelta
from jose import JWTError, jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from . import schemas, crud, database, config

# OAuth2 토큰 인증 스킴 설정 (토큰 발급 엔드포인트 지정)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# 액세스 토큰(JWT) 생성 함수
def create_access_token(data: dict, expires_delta: timedelta | None = None):
    # 토큰에 담을 데이터 복사
    to_encode = data.copy()
    # 만료 시간 설정 (기본값: 설정 파일의 ACCESS_TOKEN_EXPIRE_MINUTES)
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=config.settings.ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    # JWT 인코딩 (서명)
    encoded_jwt = jwt.encode(
        to_encode, 
        config.settings.SECRET_KEY, 
        algorithm=config.settings.ALGORITHM
    )
    return encoded_jwt

# 현재 인증된 사용자 조회 함수 (토큰 검증 및 사용자 반환)
def get_current_user(
    token: str = Depends(oauth2_scheme), 
    db: Session = Depends(database.get_db)
):
    # 인증 실패 시 반환할 예외 객체 미리 정의
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="토큰 인증 실패",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        # JWT 디코딩 및 유효성 검사
        payload = jwt.decode(
            token, 
            config.settings.SECRET_KEY, 
            algorithms=[config.settings.ALGORITHM]
        )
        email: str = payload.get("sub")  # 토큰에서 이메일(subject) 추출
        if email is None:
            raise credentials_exception
        token_data = schemas.TokenData(email=email)
    except JWTError:
        # 토큰 위조, 만료 등 오류 시 예외 발생
        raise credentials_exception
    # DB에서 사용자 정보 조회
    user = crud.get_user_by_email(db, email=token_data.email)
    if user is None:
        raise credentials_exception
    return user
