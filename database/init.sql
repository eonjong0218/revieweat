CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    role VARCHAR DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE search_history (
    id SERIAL PRIMARY KEY,
    query VARCHAR(255) NOT NULL,
    is_place BOOLEAN DEFAULT FALSE NOT NULL,
    name VARCHAR(255),
    user_id INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 인덱스 생성
CREATE INDEX idx_search_history_user_id ON search_history(user_id);
CREATE INDEX idx_search_history_created_at ON search_history(created_at);
CREATE INDEX idx_search_history_query ON search_history(query);
CREATE INDEX idx_search_history_name ON search_history(name);
CREATE INDEX idx_search_history_is_place ON search_history(is_place);
