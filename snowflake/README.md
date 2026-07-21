# Snowflake — non-dbt DDL

SQL that sets up Snowflake outside of dbt: account foundations, external
access to ADLS, and the BRONZE landing tables. Run these in a Snowsight
worksheet as `ACCOUNTADMIN`. (Least-privilege roles `ROLE_LOADER` /
`ROLE_ANALYST` come in the RBAC milestone, #10.)

Transformations (STAGING -> MARTS) live in the dbt project, not here. Note the
name clash: a Snowflake **stage** (a pointer to files, used by `COPY`) is not
the dbt **staging** layer (SQL models that clean data already in Snowflake).

## Run order

| File | What it does | Notes |
|------|--------------|-------|
| `00_databases_warehouses.sql` | Warehouse `WH_XS_ELT` (X-Small, auto-suspend), database `COMMODITY_RISK`, schemas `BRONZE`/`STAGING`/`MARTS`. | |
| `01_rbac_roles.sql` | Least-privilege roles: `ROLE_LOADER` (write; owns the schemas — used by dbt) and `ROLE_ANALYST` (read-only on MARTS — used by Power BI). | Run **after** 00/02/03: the ownership transfers assume the schemas/objects already exist. Safe to re-run. |
| `02_storage_integration.sql` | Storage integration + JSON file format + external stage over the ADLS `raw` zone. | Split: run **PART 1**, do the Azure handshake below, then run **PART 2**. |
| `03_bronze_tables.sql` | BRONZE landing table (VARIANT + load metadata) and `COPY INTO` for NBP. | |
| `04_streams_tasks.sql` | Native incremental (CDC) demo: a `STREAM` on the bronze table + a scheduled `TASK` that flattens only the delta into a working table (`nbp_fx_rates_flat`). | Complements dbt; does not replace it. The task runs only `WHEN SYSTEM$STREAM_HAS_DATA` (zero cost when idle). `ALTER TASK ... SUSPEND` to stop scheduling. |
| `06_zero_copy_clone.sql` | Creates `COMMODITY_RISK_DEV`, a **zero-copy clone** of prod, and re-applies the RBAC grants. dbt's `dev` target builds here; `prod` target is the original. | Instant, ~0 storage (copy-on-write). **Refresh = re-run** (`CREATE OR REPLACE ... CLONE`). CI's `dbt build --target dev` needs this clone to exist. (05 is reserved for a future Snowpipe demo.) |

## Azure handshake (between PART 1 and PART 2 of `02`)

Secretless external access: Snowflake gets its own identity in the Azure AD
tenant; we grant that identity read access to the storage account.

1. Run PART 1, then `DESC STORAGE INTEGRATION azure_adls_int`.
2. Open `AZURE_CONSENT_URL` in a browser and **Accept** (registers the
   Snowflake app in the Azure AD tenant).
3. Grant the Snowflake app (`AZURE_MULTI_TENANT_APP_NAME`, minus the numeric
   suffix) the **Storage Blob Data Reader** role on the storage account:

   ```bash
   az role assignment create \
     --assignee-object-id <snowflake-sp-object-id> \
     --assignee-principal-type ServicePrincipal \
     --role "Storage Blob Data Reader" \
     --scope /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<account>
   ```
4. Run PART 2 (`LIST @stg_adls_raw` should show the files).

## No secrets

These scripts contain no credentials. External access uses the storage
integration (Azure AD), not account keys or SAS tokens. The tenant ID and
resource names are identifiers, not secrets.
