-- Генерирование случайных строк
CREATE OR REPLACE FUNCTION random_range(INTEGER, INTEGER)
RETURNS INTEGER
LANGUAGE SQL
AS $$
    SELECT ($1 + FLOOR(($2 - $1 + 1) * random() ))::INTEGER;
$$;

CREATE OR REPLACE FUNCTION random_text_simple(length INTEGER)
RETURNS TEXT
LANGUAGE PLPGSQL
AS $$
DECLARE
    possible_chars TEXT := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    output TEXT := '';
    i INT4;
    pos INT4;
BEGIN
    FOR i IN 1..length LOOP
        pos := random_range(1, length(possible_chars));
        output := output || substr(possible_chars, pos, 1);
    END LOOP;
    RETURN output;
END;
$$;