-- setting company_id as the durable-key

with 
    companies as (

        select * 
        from {{ ref('stg_hubspot__companies') }}

    )

    -- expand the `merged_object_ids` column into a table of (canonical_company_id, hubspot_id) pairs
    , merged_ids as (

        select

            company_id                                          as canonical_company_id,
            trim(unnest(string_split(merged_object_ids, ';')))  as hubspot_id

        from companies
        where merged_object_ids is not null

    )

    -- every current company also resolves to itself
    , current_ids as (

        select
            company_id                                          as canonical_company_id,
            company_id                                          as hubspot_id

        from companies

    )

    , unioned as (

        select * from merged_ids
        union all
        select * from current_ids
    )

select * from unioned