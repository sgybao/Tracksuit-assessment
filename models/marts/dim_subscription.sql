with

    subscriptions as (

        select

            subscription_id,
            account_id,
            start_date,
            end_date,
            subscription_state,
            renewed_from_subscription_id

        from {{ ref('stg_subskribe__subscriptions') }}

    )

    , account_company_map as (

        select

            account_id,
            canonical_company_id

        from {{ ref('int_account_company_map') }}

    )

    -- true for the row that nothing else renews from 
    , current_flag as (

        select

            subscription_id,
            subscription_id not in (
                select renewed_from_subscription_id
                from subscriptions
                where renewed_from_subscription_id is not null
            )                                                   as is_current

        from subscriptions

    )

    , joined as (

        select

            subscriptions.subscription_id,
            subscriptions.account_id,
            account_company_map.canonical_company_id,
            -- durable key across a renewal chain. Every account currently
            -- has exactly one subscription chain (verified: 122 accounts,
            -- 122 root subscriptions), so account_id already is that durable
            -- key - no need to walk renewed_from_subscription_id for it. If
            -- an account ever starts a second, unrelated chain (e.g. churn
            -- then a brand new deal) this assumption breaks and the two
            -- chains would incorrectly share a lineage id (see
            -- assumptions.md).
            subscriptions.account_id                            as subscription_lineage_id,
            current_flag.is_current,
            subscriptions.start_date,
            subscriptions.end_date,
            subscriptions.subscription_state,
            subscriptions.renewed_from_subscription_id,
            (subscriptions.renewed_from_subscription_id 
                is not null)                                    as is_renewal

        from subscriptions
        left join account_company_map using (account_id)
        left join current_flag using (subscription_id)

    )

select * from joined
