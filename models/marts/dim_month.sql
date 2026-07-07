/*  
  This model spans every month from the earliest subscription/invoice date through
  the latest, which runs past the last real invoice into the future for
  subscriptions still under contract. Reporting models that need a "today"
  (e.g. GRR anchoring to the last month with real invoice activity) define
  that separately rather than assuming it's the max month here.
*/

{% set bounds_query %}

    select

        date_trunc('month', min(d))                             as min_date,
        date_trunc('month', max(d))                             as max_date

    from (

        select start_date                                       as d
        from {{ ref('stg_subskribe__subscriptions') }}

        union

        select end_date                                         as d
        from {{ ref('stg_subskribe__subscriptions') }}

        union

        select invoice_date                                     as d
        from {{ ref('stg_subskribe__invoices') }}

    ) as dates

{% endset %}

with
    spine as (
        {{ date_spine_from_query(bounds_query, datepart='month') }}
    )

    , final as (

        select

            date_month::date                            as month_date,
            year(date_month)::int                       as year,
            month(date_month)::int                      as month_number,
            quarter(date_month)::int                    as quarter

        from spine
    )

select * from final
