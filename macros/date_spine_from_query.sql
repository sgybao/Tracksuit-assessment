{% macro date_spine_from_query(bounds_query, datepart='month') %}
{#-
    Wraps dbt_utils.date_spine for cases where the start/end dates aren't
    known literals but come from a query against real tables (dbt_utils'
    date_spine can't take a CTE local to the calling model as a bound,
    since it probes the bounds with its own standalone query before the
    spine is built).

    bounds_query: a SQL query (as a string) whose first two selected
    columns are the min and max dates to span, e.g.:

        select min(some_date), max(some_date) from {{ ref('my_model') }}
-#}
{%- if execute -%}
    {%- set bounds = run_query(bounds_query) -%}
    {%- set min_date = bounds.columns[0].values()[0] -%}
    {%- set max_date = bounds.columns[1].values()[0] -%}
{%- else -%}
    {#- dbt's parse-time pass doesn't run queries; these placeholders just
    need to produce valid SQL so the model can be parsed into the DAG -#}
    {%- set min_date = '2020-01-01' -%}
    {%- set max_date = '2020-01-01' -%}
{%- endif -%}

{{ dbt_utils.date_spine(
    datepart=datepart,
    start_date="cast('" ~ min_date ~ "' as date)",
    end_date="cast('" ~ max_date ~ "' as date)"
) }}
{% endmacro %}
