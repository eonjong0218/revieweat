from sqlalchemy.orm import Session
import models
from passlib.context import CryptContext

# 비밀번호 해시화를 위한 암호화 컨텍스트
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def get_user_by_email(db: Session, email: str):
    """
    주어진 이메일로 사용자를 검색
    """
    return db.query(models.User).filter(models.User.email == email).first()


def create_user(db: Session, email: str, password: str):
    """
    새 사용자 생성 (비밀번호는 해시처리)
    """
    hashed_password = pwd_context.hash(password)
    db_user = models.User(email=email, password=hashed_password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    입력한 비밀번호와 해시된 비밀번호를 비교
    """
    return pwd_context.verify(plain_password, hashed_password)
