with 

    src as (

    select * 
    from {{ source('hubspot', 'hubspot_companies') }}

    )

    , cleaned as (
        -- Trimming ID fields and company name to remove any potential leading or trailing whitespace
        select

            trim(company_id)                                    as company_id,
            trim(company_name)                                  as company_name,
            size_grouped,
            industry,
            country,
            -- nullify empty strings
            nullif(trim(merged_object_ids), '')                 as merged_object_ids,
            created_at::date                                    as created_at

        from src

    )

select * from cleaned