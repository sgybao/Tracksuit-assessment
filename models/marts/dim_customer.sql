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

    , accounts as (

        select

            account_id,
            company_name,
            currency                                            as billing_currency,
            created_at                                          as account_created_at

        from {{ ref('stg_subskribe__accounts') }}

    )

    , account_company_map as (

        select

            account_id,
            canonical_company_id,
            is_unmapped

        from {{ ref('int_account_company_map') }}

    )

    , mapped_companies as (

        select

            companies.canonical_company_id,
            companies.company_name,
            companies.size_grouped,
            companies.industry,
            companies.country,
            companies.created_at,
            companies.is_unknown_company,
            account_company_map.account_id,
            accounts.billing_currency,
            accounts.account_created_at,
            coalesce(account_company_map.is_unmapped, false)    as is_unmapped

        from companies
        left join account_company_map using (canonical_company_id)
        left join accounts using (account_id)

    )

    -- synthetic "unknown member" rows for accounts that don't resolve to any
    -- HubSpot company at all (see int_account_company_map).
    , unmapped_companies as (

        select

            account_company_map.canonical_company_id,
            accounts.company_name,
            'Unknown'                                           as size_grouped,
            'Unknown'                                           as industry,
            'Unknown'                                           as country,
            cast(null as date)                                  as created_at,
            true                                                as is_unknown_company,
            account_company_map.account_id,
            accounts.billing_currency,
            accounts.account_created_at,
            account_company_map.is_unmapped

        from account_company_map
        inner join accounts using (account_id)
        where account_company_map.is_unmapped

    )

    , unioned as (

        select * from mapped_companies
        union all
        select * from unmapped_companies

    )

select * from unioned
