with 
    src as (
    
        select
            *
        from {{ source('subskribe', 'subskribe_accounts') }}

    )

    , cleaned as (
        
        select
            
            trim(account_id)                                    as account_id,
            trim(company_name)                                  as company_name,
            trim(crmid)                                         as crm_id,
            currency,
            created_at::date                                    as created_at

        from src
    )
select * from cleaned