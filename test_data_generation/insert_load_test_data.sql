-- Run `routines.sql` before running this script

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