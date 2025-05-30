-- Users 테이블 (변경 없음)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    role VARCHAR DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Search History 테이블 (변경 없음)
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

-- Reviews 테이블 (필드명 수정)
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    place_name VARCHAR(255) NOT NULL,
    place_address VARCHAR(255),
    review_date TIMESTAMP NOT NULL,  -- visit_date -> review_date
    rating VARCHAR(10) NOT NULL,
    companion VARCHAR(255),
    review_text TEXT NOT NULL,       -- content -> review_text
    image_paths TEXT,                -- image_urls -> image_paths
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Reviews 인덱스
CREATE INDEX idx_reviews_user_id ON reviews(user_id);
CREATE INDEX idx_reviews_review_date ON reviews(review_date);
CREATE INDEX idx_reviews_place_name ON reviews(place_name);
CREATE INDEX idx_reviews_rating ON reviews(rating);
CREATE INDEX idx_reviews_created_at ON reviews(created_at);
