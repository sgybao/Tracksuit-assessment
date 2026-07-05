with 
    src as (
    
        select
            *
        from {{ source('subskribe', 'subskribe_invoices') }}

    )

    , cleaned as (
        
        select
            
            trim(invoice_id)                                    as invoice_id,
            trim(account_id)                                    as account_id,
            trim(subscription_id)                               as subscription_id,

            invoice_date::date                                  as invoice_date,

            total::decimal(10, 2)                               as total,
            total_nzd::decimal(10, 2)                           as total_nzd,
            currency,
            status

        from src
    )
select * from cleaned