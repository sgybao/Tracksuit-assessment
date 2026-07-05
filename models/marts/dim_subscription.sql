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

    , accounts as (

        select

            account_id,
            canonical_company_id

        from {{ ref('dim_account') }}

    )

    , joined as (

        select

            subscriptions.subscription_id,
            subscriptions.account_id,
            accounts.canonical_company_id,
            subscriptions.start_date,
            subscriptions.end_date,
            subscriptions.subscription_state,
            subscriptions.renewed_from_subscription_id,
            (subscriptions.renewed_from_subscription_id is not null)  as is_renewal

        from subscriptions
        left join accounts using (account_id)

    )

select * from joined
