from datetime import datetime, timedelta
from jose import JWTError, jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from . import schemas, crud, database, config
import logging

# 로거 설정
logger = logging.getLogger(__name__)

# OAuth2 토큰 인증 스킴 설정 (토큰 발급 엔드포인트 지정)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# 액세스 토큰(JWT) 생성 함수
def create_access_token(data: dict, expires_delta: timedelta | None = None):
    try:
        # 설정 값 검증
        if not config.settings.SECRET_KEY:
            raise ValueError("SECRET_KEY가 설정되지 않았습니다")
        if not config.settings.ALGORITHM:
            raise ValueError("ALGORITHM이 설정되지 않았습니다")
            
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
    except (ValueError, TypeError) as e:
        logger.error(f"토큰 생성 설정 오류: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="토큰 생성 중 서버 오류가 발생했습니다"
        )
    except Exception as e:
        logger.error(f"토큰 생성 예상치 못한 오류: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="토큰 생성 중 오류가 발생했습니다"
        )

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
    except JWTError as e:
        # 토큰 위조, 만료 등 오류 시 예외 발생
        logger.warning(f"JWT 검증 실패: {e}")
        raise credentials_exception
    except Exception as e:
        logger.error(f"토큰 검증 예상치 못한 오류: {e}")
        raise credentials_exception
    
    try:
        # DB에서 사용자 정보 조회
        user = crud.get_user_by_email(db, email=token_data.email)
        if user is None:
            logger.warning(f"사용자를 찾을 수 없음: {token_data.email}")
            raise credentials_exception
        return user
    except SQLAlchemyError as e:
        logger.error(f"데이터베이스 오류: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="데이터베이스 연결에 문제가 발생했습니다"
        )
    except Exception as e:
        logger.error(f"사용자 조회 예상치 못한 오류: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="사용자 인증 중 오류가 발생했습니다"
        )
