with

    subscriptions as (

        select

            subscription_id,
            canonical_company_id,
            start_date,
            end_date

        from {{ ref('dim_subscription') }}

    )

    , invoices as (

        select

            subscription_id,
            date_trunc('month', invoice_date)                   as month_date,
            sum(total_nzd)                                      as recognised_revenue_nzd

        from {{ ref('stg_subskribe__invoices') }}
        -- assumption: voided invoices don't count as revenue, so ignore them. See assumptions.md.
        where status != 'VOIDED'
        group by all

    )

    , subscription_months as (

        select

            subscriptions.subscription_id,
            dim_month.month_date

        from subscriptions
        inner join {{ ref('dim_month') }} as dim_month
            on dim_month.month_date >= date_trunc('month', subscriptions.start_date)
            and dim_month.month_date <= date_trunc('month', subscriptions.end_date)

    )

    , coverage_months as (

        select subscription_id, month_date from subscription_months
        -- early or late invoice activity that falls outside the subscription's start/end
        union
        select subscription_id, month_date from invoices

    )

    , final as (

        select

            coverage_months.subscription_id,
            coverage_months.month_date,
            subscriptions.canonical_company_id,
            (subscription_months.subscription_id is not null)   as is_within_subscription_term,
            coalesce(invoices.recognised_revenue_nzd, 0)        as recognised_revenue_nzd

        from coverage_months
        left join subscriptions using (subscription_id)
        left join subscription_months using (subscription_id, month_date)
        left join invoices using (subscription_id, month_date)

    )

select * from final