-- =============================================================================
-- 03 - BRONZE landing table + COPY INTO for NBP
-- Raw JSON landed as-is into a VARIANT column, plus load metadata.
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE COMMODITY_RISK;
USE SCHEMA BRONZE;
USE WAREHOUSE WH_XS_ELT;

-- Landing table: the whole JSON document in a VARIANT, plus lineage columns.
CREATE TABLE IF NOT EXISTS NBP_FX_RATES_RAW (
    raw        VARIANT,        -- the raw NBP JSON, untouched
    _src_file  STRING,         -- which file it came from (lineage)
    _loaded_at TIMESTAMP_NTZ   -- when we loaded it
);

-- Load. The FROM sub-query lets us add the two metadata columns alongside the
-- file content ($1 = the parsed JSON of each document).
COPY INTO NBP_FX_RATES_RAW (raw, _src_file, _loaded_at)
FROM (
    SELECT $1,
           METADATA$FILENAME,
           CURRENT_TIMESTAMP()
    FROM @stg_adls_raw
)
FILE_FORMAT = (FORMAT_NAME = 'ff_json')
PATTERN     = '.*nbp_table_a_.*[.]json'   -- only NBP table A files
ON_ERROR    = 'ABORT_STATEMENT';

-- ---------------------------------------------------------------------------
-- Verification
-- ---------------------------------------------------------------------------

-- Row count + load metadata.
SELECT COUNT(*) AS row_count FROM NBP_FX_RATES_RAW;

SELECT _src_file,
       _loaded_at,
       raw[0]:"table"::string      AS table_name,
       raw[0]:effectiveDate::date  AS effective_date,
       ARRAY_SIZE(raw[0]:rates)    AS n_currencies
FROM NBP_FX_RATES_RAW;

-- Prove the real FX rates are queryable: USD/PLN and EUR/PLN.
SELECT r.value:code::string AS currency,
       r.value:mid::float   AS mid_pln
FROM NBP_FX_RATES_RAW,
     LATERAL FLATTEN(input => raw[0]:rates) r
WHERE r.value:code::string IN ('USD', 'EUR');

-- ---------------------------------------------------------------------------
-- EIA petroleum spot prices (api_key source, #15). One generic table holds any
-- series (WTI RWTC, Brent RBRTE, ...); the PATTERN matches every EIA spot file,
-- so adding a series is just a sources.json entry.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS EIA_PETROLEUM_SPOT_RAW (
    raw        VARIANT,
    _src_file  STRING,
    _loaded_at TIMESTAMP_NTZ
);

COPY INTO EIA_PETROLEUM_SPOT_RAW (raw, _src_file, _loaded_at)
FROM (
    SELECT $1,
           METADATA$FILENAME,
           CURRENT_TIMESTAMP()
    FROM @stg_adls_raw
)
FILE_FORMAT = (FORMAT_NAME = 'ff_json')
PATTERN     = '.*eia_.*_spot_.*[.]json'   -- eia_wti_spot_*, eia_brent_spot_*, ...
ON_ERROR    = 'ABORT_STATEMENT';

-- Verify: which series landed, and the latest price of each.
SELECT d.value:series::string      AS series,
       COUNT(*)                    AS n_days,
       MAX(d.value:period::date)   AS latest_date
FROM EIA_PETROLEUM_SPOT_RAW,
     LATERAL FLATTEN(input => raw:response:data) d
GROUP BY series;

-- ---------------------------------------------------------------------------
-- Open-Meteo daily weather (keyless, #22). The document stores PARALLEL arrays
-- under raw:daily (time[i] matches temperature_2m_max[i]); staging zips them.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS OPENMETEO_WEATHER_RAW (
    raw        VARIANT,
    _src_file  STRING,
    _loaded_at TIMESTAMP_NTZ
);

COPY INTO OPENMETEO_WEATHER_RAW (raw, _src_file, _loaded_at)
FROM (
    SELECT $1,
           METADATA$FILENAME,
           CURRENT_TIMESTAMP()
    FROM @stg_adls_raw
)
FILE_FORMAT = (FORMAT_NAME = 'ff_json')
PATTERN     = '.*openmeteo_.*[.]json'
ON_ERROR    = 'ABORT_STATEMENT';

-- Verify: how many days landed and the temperature range.
SELECT ARRAY_SIZE(raw:daily:time)                          AS n_days,
       raw:daily:time[0]::date                             AS first_day,
       raw:daily:temperature_2m_max[0]::float              AS first_temp_max_c
FROM OPENMETEO_WEATHER_RAW;

-- ---------------------------------------------------------------------------
-- ECB euro short-term rate (STR), first CSV source (#19). The ECB SDMX CSV is
-- wide (29 columns); we project the ones we need by position in the COPY. This
-- bronze is structured (not VARIANT) because the source is CSV, not JSON.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ECB_ESTR_RAW (
    series_key STRING,
    obs_date   DATE,
    obs_value  NUMBER(18, 6),   -- rate in percent
    title      STRING,
    unit       STRING,
    _src_file  STRING,
    _loaded_at TIMESTAMP_NTZ
);

COPY INTO ECB_ESTR_RAW (series_key, obs_date, obs_value, title, unit, _src_file, _loaded_at)
FROM (
    SELECT $1,                    -- KEY
           $5::date,              -- TIME_PERIOD
           $6::number(18, 6),     -- OBS_VALUE
           $25,                   -- TITLE
           $28,                   -- UNIT_MEASURE
           METADATA$FILENAME,
           CURRENT_TIMESTAMP()
    FROM @stg_adls_raw
)
FILE_FORMAT = (FORMAT_NAME = 'ff_csv')
PATTERN     = '.*ecb_estr_.*[.]csv'
ON_ERROR    = 'ABORT_STATEMENT';   -- data is clean; ON_ERROR=CONTINUE/SKIP_FILE are the alternatives

SELECT COUNT(*) AS bronze_rows, MIN(obs_date) AS from_date, MAX(obs_date) AS to_date,
       MAX_BY(obs_value, obs_date) AS latest_rate_pct
FROM ECB_ESTR_RAW;
