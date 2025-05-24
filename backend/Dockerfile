# 1. 베이스 이미지로 Python 3.11 사용
FROM python:3.11-slim

# 2. 작업 디렉터리 설정
WORKDIR /app

# 3. 의존성 복사 및 설치
COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# 4. 소스 코드 복사
COPY . /app

# 5. wait-for-it.sh 복사 및 실행 권한 부여
COPY wait-for-it.sh /app/wait-for-it.sh
RUN chmod +x /app/wait-for-it.sh

# 6. 환경 변수 설정 (예: 포트)
ENV PORT=8000

# 7. 컨테이너 실행 시 DB가 준비될 때까지 대기 후 FastAPI 앱 실행
CMD ["/app/wait-for-it.sh", "db:5432", "--", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
