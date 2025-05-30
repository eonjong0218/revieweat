from fastapi import Depends
from sqlalchemy.orm import Session
from . import database, auth

# 데이터베이스 세션을 의존성으로 주입하는 함수
get_db = database.get_db

# 현재 인증된(로그인된) 사용자를 의존성으로 주입하는 함수
get_current_user = auth.get_current_user