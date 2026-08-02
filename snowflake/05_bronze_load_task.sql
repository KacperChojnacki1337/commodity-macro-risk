-- =============================================================================
-- 05 - Automated ADLS -> BRONZE load: stored procedure + scheduled Task
-- Replaces the manual COPY runs from 03_bronze_tables.sql. One procedure runs
-- every source's COPY (each idempotent: COPY skips files already loaded, so only
-- new daily files land), and a single scheduled Task calls it once a day.
-- This is the "no manual trigger" automation for the bronze layer.
-- =============================================================================

USE ROLE ACCOUNTADMIN;   -- inherits ROLE_LOADER (owner of BRONZE) via the hierarchy
USE DATABASE COMMODITY_RISK;
USE SCHEMA BRONZE;
USE WAREHOUSE WH_XS_ELT;

-- Procedure: run the COPY for each source. ON_ERROR=ABORT_STATEMENT so a bad file
-- fails the task loudly (visible in TASK_HISTORY) instead of silently skipping.
CREATE OR REPLACE PROCEDURE sp_load_bronze()
    RETURNS STRING
    LANGUAGE SQL
AS
$$
BEGIN
    COPY INTO NBP_FX_RATES_RAW (raw, _src_file, _loaded_at)
    FROM (SELECT $1, METADATA$FILENAME, CURRENT_TIMESTAMP() FROM @stg_adls_raw)
    FILE_FORMAT = (FORMAT_NAME = 'ff_json')
    PATTERN = '.*nbp_table_a_.*[.]json' ON_ERROR = 'ABORT_STATEMENT';

    COPY INTO EIA_PETROLEUM_SPOT_RAW (raw, _src_file, _loaded_at)
    FROM (SELECT $1, METADATA$FILENAME, CURRENT_TIMESTAMP() FROM @stg_adls_raw)
    FILE_FORMAT = (FORMAT_NAME = 'ff_json')
    PATTERN = '.*eia_.*_spot_.*[.]json' ON_ERROR = 'ABORT_STATEMENT';

    COPY INTO OPENMETEO_WEATHER_RAW (raw, _src_file, _loaded_at)
    FROM (SELECT $1, METADATA$FILENAME, CURRENT_TIMESTAMP() FROM @stg_adls_raw)
    FILE_FORMAT = (FORMAT_NAME = 'ff_json')
    PATTERN = '.*openmeteo_.*[.]json' ON_ERROR = 'ABORT_STATEMENT';

    COPY INTO ECB_ESTR_RAW (series_key, obs_date, obs_value, title, unit, _src_file, _loaded_at)
    FROM (SELECT $1, $5::date, $6::number(18, 6), $25, $28, METADATA$FILENAME, CURRENT_TIMESTAMP() FROM @stg_adls_raw)
    FILE_FORMAT = (FORMAT_NAME = 'ff_csv')
    PATTERN = '.*ecb_estr_.*[.]csv' ON_ERROR = 'ABORT_STATEMENT';

    COPY INTO EUROSTAT_CIVIL_ENG_RAW (raw, _src_file, _loaded_at)
    FROM (SELECT $1, METADATA$FILENAME, CURRENT_TIMESTAMP() FROM @stg_adls_raw)
    FILE_FORMAT = (FORMAT_NAME = 'ff_json')
    PATTERN = '.*eurostat_civil_eng_.*[.]json' ON_ERROR = 'ABORT_STATEMENT';

    COPY INTO GUS_ROADS_RAW (raw, _src_file, _loaded_at)
    FROM (SELECT $1, METADATA$FILENAME, CURRENT_TIMESTAMP() FROM @stg_adls_raw)
    FILE_FORMAT = (FORMAT_NAME = 'ff_json')
    PATTERN = '.*gus_expressways_motorways_.*[.]json' ON_ERROR = 'ABORT_STATEMENT';

    RETURN 'bronze load complete';
END;
$$;

-- Task: run the procedure daily at 05:30 UTC (after the ADF ingest trigger at
-- 05:00 lands the day's files; dbt then builds marts at 06:00 via GitHub cron).
CREATE OR REPLACE TASK bronze_load_task
    WAREHOUSE = WH_XS_ELT
    SCHEDULE  = 'USING CRON 30 5 * * * UTC'
    COMMENT   = 'Daily ADLS -> BRONZE load for all sources'
AS
    CALL sp_load_bronze();

-- Tasks are created suspended; resume to put it on the schedule.
ALTER TASK bronze_load_task RESUME;

-- --- Inspection ---
-- SHOW TASKS LIKE 'bronze_load_task';
-- CALL sp_load_bronze();                       -- run now (don't wait for schedule)
-- SELECT name, state, scheduled_time, query_start_time, error_message
--   FROM TABLE(information_schema.task_history(task_name => 'BRONZE_LOAD_TASK'))
--   ORDER BY scheduled_time DESC;
