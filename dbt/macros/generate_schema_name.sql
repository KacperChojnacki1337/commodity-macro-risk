{#
    Override of dbt's built-in generate_schema_name.

    dbt's default concatenates the target schema with the custom one
    (target "STAGING" + custom "MARTS" -> "STAGING_MARTS"). That prefixing
    exists so developers sharing one account don't overwrite each other.

    We don't need it: our dev/prod separation is by DATABASE (prod:
    COMMODITY_RISK, dev: a zero-copy clone), not by schema prefix. So we take
    the custom schema name as-is and land in the exact schemas created in
    snowflake/00_databases_warehouses.sql: STAGING and MARTS.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
