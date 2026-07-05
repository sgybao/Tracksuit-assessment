with

    companies as (

        select

            company_id                                          as canonical_company_id,
            company_name,
            size_grouped,
            industry,
            country,
            created_at,
            false                                               as is_unknown_company

        from {{ ref('stg_hubspot__companies') }}

    )

    -- synthetic "unknown member" rows for accounts that don't resolve to any
    -- HubSpot company at all (see int_account_company_map) - one row per
    -- unmapped account, not a single shared placeholder, so unrelated
    -- unmapped companies don't collapse into one "customer" downstream.
    -- company_name comes from Subskribe's own record, since that's real and
    -- known even though the HubSpot match isn't; the CRM-sourced attributes
    -- genuinely aren't known so those stay 'Unknown'.
    , unmapped_companies as (

        select

            account_company_map.canonical_company_id,
            accounts.company_name,
            'Unknown'                                           as size_grouped,
            'Unknown'                                           as industry,
            'Unknown'                                           as country,
            cast(null as date)                                  as created_at,
            true                                                as is_unknown_company

        from {{ ref('int_account_company_map') }} as account_company_map
        inner join {{ ref('stg_subskribe__accounts') }} as accounts
            using (account_id)
        where account_company_map.is_unmapped

    )

    , unioned as (

        select * from companies
        union all
        select * from unmapped_companies

    )

select * from unioned
