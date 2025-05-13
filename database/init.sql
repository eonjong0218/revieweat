-- init.sql
-- 데이터베이스 생성
CREATE DATABASE IF NOT EXISTS revieweat_db;
USE revieweat_db;

-- 사용자 테이블
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,  -- 해시된 비밀번호 저장
    nickname VARCHAR(50) NOT NULL,
    profile_image VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_email (email)
);

-- 카테고리 테이블
CREATE TABLE IF NOT EXISTS categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    icon VARCHAR(100),
    priority INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE
);

-- 음식점 테이블
CREATE TABLE IF NOT EXISTS restaurants (
    restaurant_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    phone VARCHAR(20),
    business_hours VARCHAR(255),
    description TEXT,
    website VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_verified BOOLEAN DEFAULT FALSE,
    average_rating DECIMAL(2, 1) DEFAULT 0.0,
    review_count INT DEFAULT 0,
    INDEX idx_location (latitude, longitude),
    INDEX idx_name (name)
);

-- 음식점-카테고리 매핑 테이블 (다대다 관계)
CREATE TABLE IF NOT EXISTS restaurant_categories (
    restaurant_id INT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (restaurant_id, category_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
);

-- 음식점 이미지 테이블
CREATE TABLE IF NOT EXISTS restaurant_images (
    image_id INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_id INT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    is_main BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id) ON DELETE CASCADE
);

-- 리뷰 테이블
CREATE TABLE IF NOT EXISTS reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    restaurant_id INT NOT NULL,
    rating DECIMAL(2, 1) NOT NULL,
    content TEXT,
    visit_date DATE,
    companion_type ENUM('alone', 'friend', 'family', 'couple', 'business', 'other') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_verified BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id) ON DELETE CASCADE,
    INDEX idx_restaurant_id (restaurant_id),
    INDEX idx_user_id (user_id)
);

-- 리뷰 이미지 테이블
CREATE TABLE IF NOT EXISTS review_images (
    image_id INT AUTO_INCREMENT PRIMARY KEY,
    review_id INT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (review_id) REFERENCES reviews(review_id) ON DELETE CASCADE
);

-- 북마크(즐겨찾기) 테이블
CREATE TABLE IF NOT EXISTS bookmarks (
    user_id INT NOT NULL,
    restaurant_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, restaurant_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id) ON DELETE CASCADE
);

-- 방문 기록 테이블
CREATE TABLE IF NOT EXISTS visit_history (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    restaurant_id INT NOT NULL,
    visit_date DATE NOT NULL,
    has_review BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id) ON DELETE CASCADE,
    INDEX idx_user_visit (user_id, visit_date)
);

-- 검색 기록 테이블
CREATE TABLE IF NOT EXISTS search_history (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    search_query VARCHAR(255) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    category_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL
);

-- 기본 카테고리 데이터 삽입
INSERT INTO categories (name, icon, priority, is_active) VALUES
('전체', 'all_icon', 1, TRUE),
('한식', 'korean_food_icon', 2, TRUE),
('중식', 'chinese_food_icon', 3, TRUE),
('일식', 'japanese_food_icon', 4, TRUE),
('양식', 'western_food_icon', 5, TRUE),
('카페', 'cafe_icon', 6, TRUE),
('베이커리', 'bakery_icon', 7, TRUE),
('패스트푸드', 'fastfood_icon', 8, TRUE),
('분식', 'snack_icon', 9, TRUE),
('술집', 'bar_icon', 10, TRUE);

-- 인덱스 생성
CREATE INDEX idx_restaurant_rating ON restaurants(average_rating);
CREATE INDEX idx_restaurant_reviews ON restaurants(review_count);
CREATE INDEX idx_review_rating ON reviews(rating);
CREATE INDEX idx_review_date ON reviews(created_at);
