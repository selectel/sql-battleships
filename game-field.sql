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

insert into game_field (id) values (1), (2), (3), (4), (5), (6), (7), (8), (9), (10);

drop table if exists game_event;
create table game_event
(
  id serial,
  player text not null,
  event text not null,
  cell text default null
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
    execute 'insert into game_event_' || game_id || ' (player, event) values (''b'', ''connected'');';
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