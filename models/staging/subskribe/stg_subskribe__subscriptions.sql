with 
    src as (
    
        select
            *
        from {{ source('subskribe', 'subskribe_subscriptions') }}

    )

    , cleaned as (
        
        select
            
            trim(subscription_id)                               as subscription_id,
            trim(account_id)                                    as account_id,
            trim(renewed_from_subscription_id)                  as renewed_from_subscription_id,
            
            subscription_state, 
            
            start_date::date                                    as start_date,
            end_date::date                                      as end_date,
            cancelled_date::date                                as cancelled_date,
            creation_time::datetime                             as created_at,
            updated_at::datetime                                as updated_at

        from src
    )
select * from cleaned