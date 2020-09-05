create or replace procedure screen_loop()
language plpgsql
as $$
declare
    keyboard_session_id text;
    game_id text;
    txt text;
begin
    select keyboard_init() into keyboard_session_id;

    loop
        select keyboard_read(keyboard_session_id) into txt;

        if txt = 'new game;' then
            raise info 'Starting new game...';
            select game_create() into game_id;
            commit;
            raise info 'Game ID: %', game_id;
            call game_wait_for_opponent(game_id);
            exit;
        end if;

        if substr(txt, 0, 8) = 'connect' then
            select substr(txt, 9, 10) into game_id;
            raise info 'Connecting to %...', game_id;
            call game_connect(game_id);
            raise info 'Connected!';
            exit;
        end if;
    end loop;

    raise info 'Game started!';
end
$$;