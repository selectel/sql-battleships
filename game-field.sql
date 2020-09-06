drop table if exists game_field;
create table game_field
(
  id serial,
  a varchar(1) default '.',
  b varchar(1) default '.',
  c varchar(1) default '.',
  d varchar(1) default '.',
  e varchar(1) default '.',
  f varchar(1) default '.',
  g varchar(1) default '.',
  h varchar(1) default '.',
  i varchar(1) default '.',
  j varchar(1) default '.'
);

insert into game_field (id) values (0), (1), (2), (3), (4), (5), (6), (7), (8), (9);

drop table if exists game_event;
create table game_event
(
  id timestamp default now(),
  player text not null,
  event text not null,
  cell text default null
);

drop table if exists game_ships;
create table game_ships
(
  id serial,
  start_cell text,
  end_cell text,
  length int,
  health int
);

create or replace function game_create() returns text
language plpgsql
as $$
declare
    game_id text;
begin
    select random_text_simple(10) into game_id;

    execute 'create table game_field_' || game_id || '_a as select * from game_field;';
    execute 'create table game_field_' || game_id || '_b as select * from game_field;';
    execute 'create table game_ships_' || game_id || '_a as select * from game_ships;';
    execute 'create table game_ships_' || game_id || '_b as select * from game_ships;';
    execute 'create table game_event_' || game_id || ' as table game_event with no data;';
    execute 'insert into game_event_' || game_id || ' (player, event) values (''a'', ''connected'');';

    return game_id;
end
$$;

create or replace procedure game_connect(game_id text)
language plpgsql
as $$
declare
    table_exists bool;
begin
    execute 'SELECT EXISTS(SELECT FROM pg_tables WHERE  schemaname = ''public'' AND tablename  = lower(''game_event_' || game_id ||'''));' into  table_exists;
    if table_exists = false then
        raise exception 'No such game!';
    end if;
    commit;
    execute 'insert into game_event_' || game_id || ' (player, event) values (''b'', ''connected'');';
    commit;
end
$$;

create or replace procedure game_wait_for_opponent(game_id text)
language plpgsql
as $$
declare
    c int;
begin
    loop
        execute 'select count(*) from game_event_' || game_id || ' where event = ''connected'' and player = ''b'';' into c;
        if c > 0 then
            exit;
        end if;
        perform pg_sleep(1);
    end loop;
end;
$$;



create or replace procedure game_wait_for_ready(game_id text)
language plpgsql
as $$
declare
    c int;
begin
    loop
        execute 'select count(*) from game_event_' || game_id || ' where event = ''ready'';' into c;
        if c = 2 then
            exit;
        end if;
        perform pg_sleep(1);
    end loop;
end;
$$;

create or replace procedure game_print_single_field(game_id text, player text)
language plpgsql
as $$
declare
    r record;
    ships int;
    additional text := '';
begin
    raise info '.. A B C D E F G H I J';
    for r in execute 'select * from game_field_' || game_id || '_' || player || ' order by id' loop
        select '' into additional;
        if r.id = 3 then
            execute format('select count(*) from game_ships_%s_%s', game_id, player) into ships;
            if ships = 4 + 3 + 2 + 1 then
                select '     You: READY' into additional;
            else
                select '     You: Preparing...' into additional;
            end if;
        end if;
        if r.id = 4 then
            execute format('select count(*) from game_ships_%s_%s', game_id, chr(ascii('a') + (ascii('b') - ascii(player)))) into ships;
            if ships = 4 + 3 + 2 + 1 then
                select 'Opponent: READY' into additional;
            else
                select 'Opponent: Preparing...' into additional;
            end if;
        end if;
        raise info '% % % % % % % % % % % %', format('%2s', r.id), r.A, r.B, r.C, r.D, r.E, r.F, r.G, r.H, r.I, r.J, additional;
    end loop;
end
$$;

create or replace procedure game_place_cell(game_id text, player text, cell text, data text)
language plpgsql
as $$
declare
    col text;
    row text;
begin
    select substr(cell, 1, 1) into col;
    select substr(cell, 2, 1) into row;

    execute format('update game_field_%s_%s set %s = ''%s'' where id = %s', game_id, player, col, data, row);
end
$$;

create or replace procedure game_place_rect(game_id text, player text, from_cell text, to_cell text, data text)
language plpgsql
as $$
declare
    col_from text;
    col_to text;
    row_from text;
    row_to text;
    cell text;
begin
    select substr(from_cell, 1, 1) into col_from;
    select substr(from_cell, 2, 1) into row_from;
    select substr(to_cell, 1, 1) into col_to;
    select substr(to_cell, 2, 1) into row_to;

    for i in least(ascii(col_from), ascii(col_to))..greatest(ascii(col_from), ascii(col_to)) loop
        for j in least(row_from, row_to)..greatest(row_from, row_to) loop
            select format('%s%s', chr(i), j) into cell;
            call game_place_cell(game_id, player, cell, data);
        end loop;
    end loop;
end
$$;

create or replace procedure game_place_ships_loop(keyboard_session_id text, game_id text, player text)
language plpgsql
as $$
declare
    request text;
    ship_len int;
    ships int;
    can_place bool;
begin
    loop
       commit;
       call game_print_single_field(game_id, player);

       execute format('select count(*) from game_ships_%s_%s', game_id, player) into ships;
       if ships = 4 + 3 + 2 + 1 then
           commit;
           execute format('insert into game_event_%s (player, event) values (''%s'', ''ready'');', game_id, player);
           commit;
           exit;
       end if;

       raise info '';
       raise info 'You can place:';
       execute format('select 4 - count(*) from game_ships_%s_%s where length = 1;', game_id, player) into ships;
       raise info '    S    x%', ships;
       execute format('select 3 - count(*) from game_ships_%s_%s where length = 2;', game_id, player)  into ships;
       raise info '    SS   x%', ships;
       execute format('select 2 - count(*) from game_ships_%s_%s where length = 3;', game_id, player)  into ships;
       raise info '    SSS  x%', ships;
       execute format('select 1 - count(*) from game_ships_%s_%s where length = 4;', game_id, player)  into ships;
       raise info '    SSSS x%', ships;
       raise info '';
       raise info 'Place ship with command "<start> <end>;". For example, "B2 B4;"';

       select keyboard_read(keyboard_session_id) into request;
       if length(request) <> 6 then
           raise warning 'incorrect length';
           perform pg_sleep(1);
           continue;
       end if;

       -- 123456
       -- B1 B4;
       if substr(request, 1, 1) <> substr(request, 4, 1) and substr(request, 2, 1) <> substr(request, 5, 1) then
           raise warning 'incorrect ship';
           perform pg_sleep(1);
           continue;
       end if;

       select
              greatest(
                  abs(ascii(substr(request, 4, 1)) - ascii(substr(request, 1, 1))),
                  abs(ascii(substr(request, 5, 1)) - ascii(substr(request, 2, 1)))
              ) + 1
       into ship_len;

       if ship_len > 4 then
           raise warning 'length of ship must be less than 5, % provided', ship_len;
           continue;
       end if;

       execute format('select (5 - %s) - count(*) from game_ships_%s_%s where length = %s;', ship_len, game_id, player, ship_len) into ships;

       if ships < 1 then
           raise warning 'No such ships';
           continue;
       end if;

       select game_check_ship_placement(game_id, player, substr(request, 1, 2), substr(request, 4, 2)) into can_place;

       if can_place = false then
           raise warning 'Can''t place ship here!';
           continue;
       end if;

       execute format('insert into game_ships_%s_%s (start_cell, end_cell, length, health) VALUES (''%s'', ''%s'', %s, %s);', game_id, player, substr(request, 1, 2), substr(request, 4, 2), ship_len, ship_len);

       call game_place_rect(game_id, player, substr(request, 1, 2), substr(request, 4, 2), 'S');

    end loop;
end
$$;

create or replace function game_check_ship_placement(game_id text, player text, from_cell text, to_cell text) returns bool
language plpgsql
as $$
declare
    col_from text;
    col_to text;
    row_from int;
    row_to int;
    cell_data text;
begin
    select substr(from_cell, 1, 1) into col_from;
    select substr(from_cell, 2, 1) into row_from;
    select substr(to_cell, 1, 1) into col_to;
    select substr(to_cell, 2, 1) into row_to;

    for i in greatest(least(ascii(col_from)-1, ascii(col_to)-1), ascii('A'))..least(greatest(ascii(col_from)+1, ascii(col_to)+1), ascii('J')) loop
        for j in greatest(least(row_from-1, row_to-1), 0)..least(greatest(row_from+1, row_to+1), 9) loop
            execute format('select %s from game_field_%s_%s where id = %s', chr(i), game_id, player, j) into cell_data;
            if cell_data <> '.' then
                return false;
            end if;
        end loop;
    end loop;
    return true;
end
$$;

create or replace procedure game_print_battle_field(game_id text, player text)
language plpgsql
as $$
declare
    r record;
    a text;
    b text;
begin
    raise info '. A B C D E F G H I J | . A B C D E F G H I J';
    for r in execute format(
        'select
            a.id as id, a.a as aa, a.b as ab, a.c as ac, a.d as ad, a.e as ae, a.f as af, a.g as ag, a.h as ah, a.i as ai, a.j as aj,
            b.a as ba, b.b as bb, b.c as bc, b.d as bd, b.e as be, b.f as bf, b.g as bg, b.h as bh, b.i as bi, b.j as bj
        from
            game_field_%s_a a,
            game_field_%s_b b
        where a.id = b.id order by id;'
    , game_id, game_id) loop

        select format('%s %s %s %s %s %s %s %s %s %s %s', r.id, r.aa, r.ab, r.ac, r.ad, r.ae, r.af, r.ag, r.ah, r.ai, r.aj) into a;
        select format('%s %s %s %s %s %s %s %s %s %s %s', r.id, r.ba, r.bb, r.bc, r.bd, r.be, r.bf, r.bg, r.bh, r.bi, r.bj) into b;

        if player = 'a' then
            raise info '% | %', a, replace(b, 'S', '.');
        else
            raise info '% | %', b, replace(a, 'S', '.');
        end if;
    end loop;
end
$$;

create or replace procedure game_battlefield_loop(keyboard_session_id text, game_id text, player text)
language plpgsql
as $$
declare
    request text;
    ship_len int;
    ships int;
    can_place bool;
begin

end
$$;