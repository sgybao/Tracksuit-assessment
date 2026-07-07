-- fails if any month between min and max month_date is missing from dim_month
with

    bounds as (
        select
            min(month_date)  as min_month,
            max(month_date)  as max_month
        from {{ ref('dim_month') }}
    )

    , expected as (
        select unnest(generate_series(min_month, max_month, interval 1 month))  as month_date
        from bounds
    )

select expected.month_date
from expected
left join {{ ref('dim_month') }} as actual using (month_date)
where actual.month_date is null
