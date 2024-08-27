-- Table `users`
CREATE TABLE IF NOT EXISTS users
(
    id            SERIAL PRIMARY KEY,
    username      VARCHAR(25) UNIQUE NOT NULL,
    email         VARCHAR(25) UNIQUE NOT NULL,
    password_hash TEXT               NOT NULL,
    password_salt TEXT               NOT NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indices for `users` table (not creating as UNIQUE idx is automatically created)
-- CREATE INDEX idx_users_username ON users USING HASH (username);
-- CREATE INDEX idx_users_email ON users USING HASH (email);


------------------------------------------------------------


-- Table `urls`
CREATE TABLE IF NOT EXISTS urls
(
    short      VARCHAR(7) PRIMARY KEY,
    long       VARCHAR   NOT NULL,
    user_id    INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL
);

-- Indices for `urls` table
CREATE INDEX idx_urls_user_id ON urls USING HASH (user_id);