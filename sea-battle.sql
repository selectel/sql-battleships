create or replace procedure screen_loop()
language plpgsql
as $$
declare
    keyboard_session_id text;
    game_id text;
    txt text;
    player text;
begin
    select keyboard_init() into keyboard_session_id;

    raise info '';
    raise info 'new game;          -- create new game server';
    raise info 'connect <game-id>; -- connect to existing game server';

    loop
        select keyboard_read(keyboard_session_id) into txt;

        if txt = 'new game;' then
            raise info 'Starting new game...';
            select game_create() into game_id;
            commit;
            raise info 'Game ID: %', game_id;
            raise info '';
            raise info 'Waiting for opponent...';
            call game_wait_for_opponent(game_id);
            select 'a' into player;
            exit;
        end if;

        if substr(txt, 0, 8) = 'connect' then
            select substr(txt, 9, 10) into game_id;
            raise info 'Connecting to %...', game_id;
            call game_connect(game_id);
            raise info 'Connected!';
            select 'b' into player;
            exit;
        end if;
    end loop;

    raise info 'Placing ships phase...';
    raise info '';

    call game_place_ships_loop(keyboard_session_id, game_id, player);

    call game_wait_for_ready(game_id);

    raise info 'All players are ready!';

    call game_battlefield_loop(keyboard_session_id, game_id, player);
end
$$;