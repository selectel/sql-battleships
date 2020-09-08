-- Логи
CREATE TABLE postgres_log
(
  log_time timestamp(3) with time zone,
  user_name text,
  database_name text,
  process_id integer,
  connection_from text,
  session_id text,
  session_line_num bigint,
  command_tag text,
  session_start_time timestamp with time zone,
  virtual_transaction_id text,
  transaction_id bigint,
  error_severity text,
  sql_state_code text,
  message text,
  detail text,
  hint text,
  internal_query text,
  internal_query_pos integer,
  context text,
  query text,
  query_pos integer,
  location text,
  application_name text,
  PRIMARY KEY (session_id, session_line_num)
);

create or replace procedure refresh_log()
language plpgsql
as $$
begin
    CREATE TEMP TABLE tmp_table
    ON COMMIT DROP
    AS
    SELECT *
    FROM postgres_log
    WITH NO DATA;
    COPY tmp_table FROM '/var/lib/postgresql/data/pg_log/postgresql.csv' WITH csv;

    INSERT INTO postgres_log
    SELECT *
    FROM tmp_table
    where query is not null and command_tag = 'idle'
    ON CONFLICT DO NOTHING;
end
$$;
