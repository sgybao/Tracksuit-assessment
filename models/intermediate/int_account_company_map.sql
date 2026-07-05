with
    canonical_companies as (

        select

            canonical_company_id,
            hubspot_id

        from {{ ref('int_company_id_map') }}
    )

    , accounts as (

        select

            account_id,
            crm_id

        from {{ ref('stg_subskribe__accounts') }}
    )

    , resolved as (

        select

            accounts.account_id,
            accounts.crm_id,
            cc.canonical_company_id,
            (cc.canonical_company_id is null)                   as is_unmapped

        from accounts
        left join canonical_companies cc
            on accounts.crm_id = cc.hubspot_id
    )

    , final as (

        select

            account_id,
            crm_id,
            /*
              a couple of accounts reference a crm_id that never resolves, even
              through int_company_id_map's merge history; park them under a
              sentinel id instead of dropping them so their revenue still
              reconciles to source (see assumptions.md)
            */
            coalesce(canonical_company_id, 'hs_unknown')        as canonical_company_id,
            is_unmapped

        from resolved
    )

select * from final