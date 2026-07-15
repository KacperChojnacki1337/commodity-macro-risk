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
