create or replace function keyboard_init()
returns text
language plpgsql
as $$
declare
    password text;
    q int := 0;
    ks_id text;
    start_time timestamp(3) with time zone;
begin
    select now() into start_time;

    select random_text_simple(8) || ';' into password;
    raise info 'Let''s connect keyboard. Open another psql process and enter "%"', password;

    loop
        select count(*) into q from postgres_log where log_time >= start_time and query = password;
        if q > 0 then
            select session_id into ks_id from postgres_log where query = password;
            exit;
        end if;
        perform pg_sleep(1);
    end loop;
    raise info 'Keyboard connected';
    return ks_id;
end
$$;

create or replace function keyboard_read(keyboard_session_id text)
returns text
language plpgsql
as $$
declare
    start_time timestamp(3) with time zone;
    q int;
    result text;
begin
    select now() into start_time;

    loop
        select query into result from postgres_log where log_time >= start_time and session_id = keyboard_session_id order by log_time desc limit 1;
        if result is not null then
            exit;
        end if;
        perform pg_sleep(1);
    end loop;

    return result;
end
$$;