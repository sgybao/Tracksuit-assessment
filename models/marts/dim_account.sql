with

    accounts as (

        select

            account_id,
            currency       as billing_currency,
            created_at     as account_created_at

        from {{ ref('stg_subskribe__accounts') }}

    )

    , account_company_map as (

        select

            account_id,
            canonical_company_id,
            is_unmapped

        from {{ ref('int_account_company_map') }}

    )

    , joined as (

        select

            accounts.account_id,
            account_company_map.canonical_company_id,
            accounts.billing_currency,
            accounts.account_created_at,
            account_company_map.is_unmapped

        from accounts
        left join account_company_map using (account_id)

    )

select * from joined
