-- =============================================================================
-- 07 - Cost controls: warehouse settings + resource monitor (credit cap)
-- The warehouse (00_*) is already X-Small with auto_suspend=60; here we add a
-- credit ceiling so a runaway workload can never burn the whole trial budget.
-- =============================================================================

USE ROLE ACCOUNTADMIN;   -- resource monitors require ACCOUNTADMIN

-- Belt: confirm/enforce the small, aggressively-suspending warehouse.
ALTER WAREHOUSE WH_XS_ELT SET
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND   = 60      -- seconds idle before it suspends (pay only for real work)
    AUTO_RESUME    = TRUE;

-- Suspenders: a credit ceiling for the whole account, per month.
-- X-Small burns ~1 credit/hour, so 20 credits/month is far above our sporadic
-- use — but the monitor SUSPENDS at 100%, so accidental overspend is impossible.
CREATE OR REPLACE RESOURCE MONITOR rm_commodity_risk
    WITH
        CREDIT_QUOTA    = 20
        FREQUENCY       = MONTHLY
        START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
        ON 75  PERCENT DO NOTIFY
        ON 90  PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND            -- let running queries finish, then suspend
        ON 110 PERCENT DO SUSPEND_IMMEDIATE; -- hard stop

-- Attach the monitor to our warehouse.
ALTER WAREHOUSE WH_XS_ELT SET RESOURCE_MONITOR = rm_commodity_risk;

-- --- Inspect ---
SHOW RESOURCE MONITORS LIKE 'rm_commodity_risk';
SHOW WAREHOUSES LIKE 'WH_XS_ELT';
