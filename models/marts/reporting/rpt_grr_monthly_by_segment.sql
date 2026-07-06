with

    customer_month_revenue as (

        select

            canonical_company_id,
            month_date,
            sum(recognised_revenue_nzd)                         as revenue

        from {{ ref('fct_subscription_monthly') }}
        group by all

    )

    -- calculate the last month with real invoice activity
    , report_bounds as (

        select 

            date_trunc('month', max(invoice_date))              as last_real_month
            
        from {{ ref('stg_subskribe__invoices') }}

    )

    , report_months as (

        select 
            dim_month.month_date
        from {{ ref('dim_month') }} as dim_month
        cross join report_bounds
        where dim_month.month_date > report_bounds.last_real_month - interval '12 months'
        and dim_month.month_date <= report_bounds.last_real_month

    )

    -- customers paying (revenue > 0) 12 months before each report month -
    -- the GRR cohort. Unmapped/unknown companies stay in - they roll up
    -- into their own 'Unknown' segment bucket rather than being hidden, so
    -- the report still reconciles to fct_subscription_monthly (see
    -- assumptions.md).
    , cohort as (

        select

            canonical_company_id,
            (month_date + interval '12 months')::date          as month_date,
            revenue                                             as revenue_m_minus_12

        from customer_month_revenue
        where revenue > 0

    )

    , capped as (

        select

            cohort.month_date,
            cohort.canonical_company_id,
            cohort.revenue_m_minus_12,
            least(coalesce(current_month.revenue, 0), cohort.revenue_m_minus_12)  as retained_revenue

        from cohort
        inner join report_months using (month_date)
        left join customer_month_revenue as current_month
            on current_month.canonical_company_id = cohort.canonical_company_id
            and current_month.month_date = cohort.month_date

    )

    , final as (

        select

            capped.month_date,
            dim_customer.size_grouped,
            sum(capped.retained_revenue) / sum(capped.revenue_m_minus_12) * 100  as grr_pct,
            count(distinct capped.canonical_company_id)                          as cohort_customers

        from capped
        inner join {{ ref('dim_customer') }} as dim_customer
            using (canonical_company_id)
        group by all

    )

select * from final
