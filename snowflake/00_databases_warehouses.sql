-- =============================================================================
-- 00 - Account foundations: warehouse, database, medallion schemas
-- Run in a Snowsight worksheet. Uses ACCOUNTADMIN for now; least-privilege
-- roles (ROLE_LOADER / ROLE_ANALYST) come later in the RBAC milestone (#10).
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- Compute engine. X-Small is the smallest/cheapest; aggressive auto-suspend and
-- initially-suspended keep credit usage near zero when idle (see cost_model.md).
CREATE WAREHOUSE IF NOT EXISTS WH_XS_ELT
    WAREHOUSE_SIZE      = 'XSMALL'
    AUTO_SUSPEND        = 60      -- seconds of idle before it suspends
    AUTO_RESUME         = TRUE    -- wakes automatically on the next query
    INITIALLY_SUSPENDED = TRUE    -- do not start (and bill) on creation
    COMMENT             = 'X-Small ELT warehouse for the commodity risk platform';

-- Database and the three medallion schemas.
CREATE DATABASE IF NOT EXISTS COMMODITY_RISK
    COMMENT = 'Commodity & Macro Risk Intelligence Platform';

USE DATABASE COMMODITY_RISK;

CREATE SCHEMA IF NOT EXISTS BRONZE
    COMMENT = 'Raw landed data (VARIANT), loaded from ADLS as-is';
CREATE SCHEMA IF NOT EXISTS STAGING
    COMMENT = 'dbt staging models (typed, renamed, deduped)';
CREATE SCHEMA IF NOT EXISTS MARTS
    COMMENT = 'dbt marts (GOLD): price risk, FX exposure, demand signals';

-- Quick confirmation of context (paste the result back).
SELECT CURRENT_ACCOUNT()  AS account,
       CURRENT_REGION()   AS region,
       CURRENT_ROLE()     AS role,
       CURRENT_VERSION()  AS version;

SHOW WAREHOUSES LIKE 'WH_XS_ELT';
SHOW SCHEMAS IN DATABASE COMMODITY_RISK;
