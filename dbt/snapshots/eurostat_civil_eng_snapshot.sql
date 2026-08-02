{#
    SCD Type 2 history of the Eurostat civil-engineering production index.

    Why here and nowhere else: Eurostat genuinely REVISES published figures
    (provisional -> revised), and can withdraw a provisional period. The rest of
    our sources are effectively append-only time series where dbt "latest-wins"
    dedup is enough. So this is the one place a snapshot adds real information:

      - strategy 'check' on index_value -> a new version row whenever a period's
        published index changes (records dbt_valid_from / dbt_valid_to).
      - invalidate_hard_deletes=true -> if a period disappears from source
        (withdrawn), its current row is closed instead of lingering forever.

    Source is the deduped staging model (one row per period_date = current
    published state), so the snapshot compares each run's current state against
    the stored history.

    Lands in STAGING (owned by ROLE_LOADER); no dedicated schema needed.
#}

{% snapshot eurostat_civil_eng_snapshot %}

{{
    config(
        target_schema='STAGING',
        unique_key='period_date',
        strategy='check',
        check_cols=['index_value'],
        invalidate_hard_deletes=true
    )
}}

select
    period_date,
    geo,
    index_value
from {{ ref('stg_eurostat__civil_eng') }}

{% endsnapshot %}
