-- Users 테이블 (세션 정보 포함)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    role VARCHAR DEFAULT 'user',
    -- 세션 관련 필드 추가
    session_token VARCHAR(500),
    is_http_only BOOLEAN DEFAULT TRUE,  -- HTTP Only 설정 체크
    is_secure BOOLEAN DEFAULT TRUE,     -- Secure 설정 체크
    session_expires_at TIMESTAMP WITH TIME ZONE,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Users 테이블 인덱스
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_session_token ON users(session_token);
CREATE INDEX idx_users_session_expires_at ON users(session_expires_at);
CREATE INDEX idx_users_is_http_only ON users(is_http_only);
CREATE INDEX idx_users_is_secure ON users(is_secure);

-- Search History 테이블 
CREATE TABLE search_history (
    id SERIAL PRIMARY KEY,
    query VARCHAR(255) NOT NULL,
    is_place BOOLEAN DEFAULT FALSE NOT NULL,
    name VARCHAR(255),
    user_id INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Search History 인덱스
CREATE INDEX idx_search_history_user_id ON search_history(user_id);
CREATE INDEX idx_search_history_created_at ON search_history(created_at);
CREATE INDEX idx_search_history_query ON search_history(query);
CREATE INDEX idx_search_history_name ON search_history(name);
CREATE INDEX idx_search_history_is_place ON search_history(is_place);

-- Reviews 테이블 
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    place_name VARCHAR(255) NOT NULL,
    place_address VARCHAR(255),
    review_date TIMESTAMP NOT NULL,  
    rating VARCHAR(10) NOT NULL,
    companion VARCHAR(255),
    review_text TEXT NOT NULL,       
    image_paths TEXT,                
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Reviews 인덱스
CREATE INDEX idx_reviews_user_id ON reviews(user_id);
CREATE INDEX idx_reviews_review_date ON reviews(review_date);
CREATE INDEX idx_reviews_place_name ON reviews(place_name);
CREATE INDEX idx_reviews_rating ON reviews(rating);
CREATE INDEX idx_reviews_created_at ON reviews(created_at);

-- 만료된 세션 정리를 위한 함수
CREATE OR REPLACE FUNCTION cleanup_expired_user_sessions()
RETURNS void AS $$
BEGIN
    UPDATE users 
    SET session_token = NULL,
        session_expires_at = NULL
    WHERE session_expires_at < now();
END;
$$ LANGUAGE plpgsql;

-- updated_at 자동 업데이트 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- users 테이블에 updated_at 트리거 추가
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
