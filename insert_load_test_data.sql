-- Helper Functions
CREATE OR REPLACE FUNCTION random_string(length INT)
    RETURNS TEXT AS
$$
DECLARE
    chars  TEXT := 'abcdefghijklmnopqrstuvwxyz0123456789';
    result TEXT := '';
BEGIN
    -- Loop to construct the random string
    FOR i IN 1..length
        LOOP
            result := result || substr(chars, (random() * (length(chars) - 1) + 1)::INT, 1);
        END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION random_url()
    RETURNS TEXT AS
$$
DECLARE
    -- Variables to store the random base URL and path
    base_url      TEXT;
    random_domain TEXT;
    random_path   TEXT;
    random_scheme TEXT;
    path_segment  TEXT;
    num_segments  INT;
    i             INT;
    random_value  FLOAT;
BEGIN
    -- Randomly select a scheme (http or https)
    random_scheme := CASE
                         WHEN RANDOM() < 0.2 THEN 'http'
                         ELSE 'https'
        END;

    -- Generate a random domain name (e.g., example123.com)
    random_domain := CONCAT(
            'gwthm', -- Prefix for the domain name
            FLOOR(RANDOM() * 10000)::TEXT, -- Random number for the domain name
            '.com'
                     );

    -- Construct the base URL with a random domain and scheme
    base_url := CONCAT(random_scheme, '://', random_domain, '/');

    -- Generate a random value to determine the number of segments
    random_value := RANDOM();

    -- Determine the number of segments based on the random value
    IF random_value < 0.15 THEN
        num_segments := FLOOR(RANDOM() * 3) + 3; -- 15% chance for 3 to 5 segments
    ELSIF random_value < 0.30 THEN
        num_segments := 1; -- 15% chance
    ELSE
        num_segments := 2; -- 70% chance
    END IF;

    FOR i IN 1..num_segments
        LOOP
            -- Generate each segment and add it to the path
            path_segment := SUBSTRING(
                    MD5(RANDOM()::TEXT), 1, 8 -- Generate a random 8-character string using MD5 hash
                            );
            random_path := CONCAT(random_path, path_segment);
            IF i < num_segments THEN
                random_path := CONCAT(random_path, '/'); -- Add a '/' separator if not the last segment
            END IF;
        END LOOP;

    -- Construct and return the full URL
    RETURN base_url || random_path;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION random_user_id()
    RETURNS INTEGER AS
$$
DECLARE
    rand_value    NUMERIC;
    random_number INTEGER;
BEGIN
    -- Generate a random value between 0 and 1
    rand_value := RANDOM();

    IF 0.10 < rand_value AND rand_value < 0.25 THEN
        -- Generate a 7-digit random number
        random_number := FLOOR(RANDOM() * 100) + 1;
        RETURN random_number;
    ELSIF rand_value < 0.10 THEN
        RETURN 8;
    ELSE
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION random_timestamp(
    base_ts TIMESTAMP,
    context TEXT
)
    RETURNS TIMESTAMP AS
$$
DECLARE
    random_days     FLOAT;
    random_seconds  INT;
    random_fraction FLOAT;
BEGIN
    -- Generate a random fraction between 0 and 1
    random_fraction := RANDOM();

    -- Check the context
    IF context = 'expires_at' THEN
        -- Apply 80% logic: use 80% fixed range of 500 days, 20% random range of 30 days
        IF random_fraction < 0.8 THEN
            -- 80% chance: use fixed range of 500 days
            random_days := RANDOM() * 500;
        ELSE
            -- 20% chance: use a different range, e.g., 30 days
            random_days := RANDOM() * 30;
        END IF;
    ELSE
        -- For 'created_at' or any other context: generate a fully random interval
        random_days := RANDOM() * 365; -- Example: random days within a year
    END IF;

    -- Convert the random number of days into seconds
    random_seconds := (random_days * 86400)::INT;
    -- 86400 seconds in a day

    -- Add the random interval to the base timestamp
    RETURN base_ts + INTERVAL '1 second' * random_seconds;
END;
$$ LANGUAGE plpgsql;


------------------------------------------------------------


-- Create 100k `users`
INSERT INTO users
SELECT gs.value                              as id,
       substring(md5(random()::text), 1, 10) as username,
       substring(md5(random()::text), 1, 10) as mail,
       substring(md5(random()::text), 1, 10) as password_hash,
       substring(md5(random()::text), 1, 5)  as password_salt
FROM generate_series(1, 100000) AS gs(value);


------------------------------------------------------------


-- Temporary table `intermediate_urls`
DROP TABLE IF EXISTS intermediate_urls;

CREATE TEMP TABLE intermediate_urls AS
SELECT (random_string(7))::varchar(7)                                     as short,
       (random_url())::varchar                                            as long,
       (random_user_id())::int                                            as user_id,
       (random_timestamp('2024-04-08 16:00:00', 'created_at'))::timestamp as created_at
FROM
    generate_series(1, 10000000); -- Generate 10 Million records


------------------------------------------------------------


-- Insert data into `urls`
INSERT INTO urls
SELECT short,
       long,
       user_id,
       created_at,
       random_timestamp(created_at, 'expires_at') AS expires_at
FROM intermediate_urls
-- in case of dupes
ON CONFLICT (short) DO NOTHING;