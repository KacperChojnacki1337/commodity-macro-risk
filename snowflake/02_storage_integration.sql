-- =============================================================================
-- 02 - External access to ADLS: storage integration, file format, external stage
-- Secretless: Snowflake gets its own identity in the Azure AD tenant; we then
-- grant that identity read access to the storage account on the Azure side.
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE COMMODITY_RISK;
USE SCHEMA BRONZE;

-- ---------------------------------------------------------------------------
-- PART 1 - create the integration, then DESC it to get the values needed on
-- the Azure side (consent URL + the app name to grant a role to).
-- ---------------------------------------------------------------------------
CREATE STORAGE INTEGRATION IF NOT EXISTS azure_adls_int
    TYPE                      = EXTERNAL_STAGE
    STORAGE_PROVIDER          = 'AZURE'
    ENABLED                   = TRUE
    AZURE_TENANT_ID           = '44aa439b-ce3a-41d9-98be-0cc816a7c11b'
    STORAGE_ALLOWED_LOCATIONS = ('azure://stcmdriskdev4ym7d.blob.core.windows.net/raw/')
    COMMENT                   = 'Read access to the ADLS raw zone (dev)';

-- Copy AZURE_CONSENT_URL and AZURE_MULTI_TENANT_APP_NAME from the result.
DESC STORAGE INTEGRATION azure_adls_int;

-- ---------------------------------------------------------------------------
-- PART 2 - run AFTER granting the Snowflake app access on Azure.
-- ---------------------------------------------------------------------------
-- JSON file format (NBP returns a JSON array; STRIP_OUTER_ARRAY makes each
-- element one row later, but for a raw single-document landing we keep it simple).
CREATE FILE FORMAT IF NOT EXISTS ff_json
    TYPE = 'JSON'
    COMMENT = 'Generic JSON file format for raw landing';

-- External stage: a pointer to the ADLS raw container via the integration.
CREATE STAGE IF NOT EXISTS stg_adls_raw
    STORAGE_INTEGRATION = azure_adls_int
    URL                 = 'azure://stcmdriskdev4ym7d.blob.core.windows.net/raw/'
    FILE_FORMAT         = ff_json
    COMMENT             = 'External stage over the ADLS raw zone (dev)';

-- Proof the stage can see our NBP file:
LIST @stg_adls_raw;
