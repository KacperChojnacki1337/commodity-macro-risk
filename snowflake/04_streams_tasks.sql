-- =============================================================================
-- 04 - Streams + Tasks: native incremental (CDC) pattern
-- A STREAM tracks new rows in BRONZE; a scheduled TASK flattens only the delta
-- and MERGEs it into a working table. Demonstrates Snowflake-native incremental
-- loading (complements the dbt path; does not replace it).
-- =============================================================================

USE ROLE ACCOUNTADMIN;   -- inherits ROLE_LOADER (owner of BRONZE) via the role hierarchy
USE DATABASE COMMODITY_RISK;
USE SCHEMA BRONZE;
USE WAREHOUSE WH_XS_ELT;

-- 1. Stream on the raw landing table. APPEND_ONLY: we only INSERT into bronze,
--    so the cheaper append-only stream is enough. It captures rows added AFTER
--    it is created (existing rows are not part of the delta).
CREATE OR REPLACE STREAM nbp_fx_rates_stream
    ON TABLE nbp_fx_rates_raw
    APPEND_ONLY = TRUE
    COMMENT = 'CDC: new NBP raw files landed since the last task run';

-- 2. Working table: flattened, typed, incrementally maintained by the task.
--    Grain: one row per (effective_date, currency_code).
CREATE TABLE IF NOT EXISTS nbp_fx_rates_flat (
    effective_date DATE,
    currency_code  STRING,
    currency_name  STRING,
    mid_rate       NUMBER(18, 6),
    table_no       STRING,
    _src_file      STRING,
    _loaded_at     TIMESTAMP_NTZ
);

-- 3. Task: on schedule, ONLY when the stream has new data, flatten the delta
--    and MERGE it into the working table. Consuming the stream in a committing
--    DML advances its offset (the "bookmark" moves forward automatically).
CREATE OR REPLACE TASK nbp_fx_rates_load_task
    WAREHOUSE = WH_XS_ELT
    SCHEDULE  = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('nbp_fx_rates_stream')
AS
    MERGE INTO nbp_fx_rates_flat AS t
    USING (
        SELECT
            d.value:effectiveDate::date  AS effective_date,
            r.value:code::string         AS currency_code,
            r.value:currency::string     AS currency_name,
            r.value:mid::number(18, 6)   AS mid_rate,
            d.value:no::string           AS table_no,
            s._src_file,
            s._loaded_at
        FROM nbp_fx_rates_stream AS s,
             LATERAL FLATTEN(input => s.raw)          AS d,
             LATERAL FLATTEN(input => d.value:rates)  AS r
    ) AS src
    ON  t.effective_date = src.effective_date
    AND t.currency_code  = src.currency_code
    WHEN MATCHED THEN UPDATE SET
        t.mid_rate      = src.mid_rate,
        t.currency_name = src.currency_name,
        t.table_no      = src.table_no,
        t._src_file     = src._src_file,
        t._loaded_at    = src._loaded_at
    WHEN NOT MATCHED THEN INSERT
        (effective_date, currency_code, currency_name, mid_rate, table_no, _src_file, _loaded_at)
        VALUES
        (src.effective_date, src.currency_code, src.currency_name, src.mid_rate, src.table_no, src._src_file, src._loaded_at);

-- Tasks are created SUSPENDED. Resume to put it on the schedule.
ALTER TASK nbp_fx_rates_load_task RESUME;

-- --- Handy inspection ---
-- SELECT SYSTEM$STREAM_HAS_DATA('nbp_fx_rates_stream');   -- is there a delta?
-- SELECT COUNT(*) FROM nbp_fx_rates_stream;               -- how many new rows
-- SHOW TASKS LIKE 'nbp_fx_rates_load_task';
-- SELECT name, state, scheduled_time, query_start_time, error_message
--   FROM TABLE(information_schema.task_history(task_name => 'NBP_FX_RATES_LOAD_TASK'))
--   ORDER BY scheduled_time DESC;
-- EXECUTE TASK nbp_fx_rates_load_task;                    -- run now (don't wait for schedule)
