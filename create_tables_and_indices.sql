-- Table `users`
CREATE TABLE IF NOT EXISTS users
(
    id              SERIAL PRIMARY KEY,
    email           VARCHAR(30) UNIQUE NOT NULL,
    -- oauth_provider  VARCHAR(25),
    -- oauth_uid       VARCHAR(50),
    hashed_password TEXT NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indices for `users` table (not creating as UNIQUE idx is automatically created)
-- CREATE INDEX idx_users_email_key ON users USING HASH (email);


------------------------------------------------------------


-- Table `urls`
CREATE TABLE IF NOT EXISTS urls
(
    short_id   VARCHAR(7) PRIMARY KEY,
    long_url   VARCHAR   NOT NULL,
    user_id    INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indices for `urls` table
CREATE INDEX idx_urls_userid_key ON urls (user_id); --USING HASH (user_id);