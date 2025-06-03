from datetime import datetime, timedelta
from jose import JWTError, jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from . import schemas, crud, database, config
import logging
import functools
import time

# 로거 설정
logger = logging.getLogger(__name__)

# OAuth2 토큰 인증 스킴 설정
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# ==================== 데코레이터 정의 ====================

# 실행 시간 측정 데코레이터
def measure_execution_time(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        start_time = time.time()
        result = func(*args, **kwargs)
        end_time = time.time()
        logger.info(f"⏱️ {func.__name__} 실행 시간: {end_time - start_time:.4f}초")
        return result
    return wrapper

# 인증 활동 로그 데코레이터
def log_auth_activity(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        logger.info(f"🔐 [{timestamp}] {func.__name__} 호출")
        try:
            result = func(*args, **kwargs)
            logger.info(f"✅ [{timestamp}] {func.__name__} 성공")
            return result
        except Exception as e:
            logger.warning(f"❌ [{timestamp}] {func.__name__} 실패: {e}")
            raise
    return wrapper

# 에러 핸들링 데코레이터
def handle_auth_errors(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except JWTError as e:
            logger.warning(f"🚨 JWT 오류: {e}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="토큰 인증 실패",
                headers={"WWW-Authenticate": "Bearer"},
            )
        except SQLAlchemyError as e:
            logger.error(f"🚨 DB 오류: {e}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="데이터베이스 연결에 문제가 발생했습니다"
            )
    return wrapper

# ==================== 기존 함수에 데코레이터 적용 ====================

@measure_execution_time
@log_auth_activity
@handle_auth_errors
def create_access_token(data: dict, expires_delta: timedelta | None = None):
    # 설정 값 검증
    if not config.settings.SECRET_KEY:
        raise ValueError("SECRET_KEY가 설정되지 않았습니다")
    if not config.settings.ALGORITHM:
        raise ValueError("ALGORITHM이 설정되지 않았습니다")
        
    # 토큰에 담을 데이터 복사
    to_encode = data.copy()
    # 만료 시간 설정
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=config.settings.ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    # JWT 인코딩 (서명)
    encoded_jwt = jwt.encode(
        to_encode, 
        config.settings.SECRET_KEY, 
        algorithm=config.settings.ALGORITHM
    )
    return encoded_jwt

@measure_execution_time
@log_auth_activity
@handle_auth_errors
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
    
    # JWT 디코딩 및 유효성 검사
    payload = jwt.decode(
        token, 
        config.settings.SECRET_KEY, 
        algorithms=[config.settings.ALGORITHM]
    )
    email: str = payload.get("sub")
    if email is None:
        raise credentials_exception
    token_data = schemas.TokenData(email=email)
    
    # DB에서 사용자 정보 조회
    user = crud.get_user_by_email(db, email=token_data.email)
    if user is None:
        logger.warning(f"사용자를 찾을 수 없음: {token_data.email}")
        raise credentials_exception
    return user
