Hello. here is a README.md file from a take-home assignment I need to work on. Take a read of this file and use plan mode to tell me what you think and how you'd plan for it - you don't need to write any code, I just want to see your thinking and plan/assumptions.

Could you verify my discovery - there's not one invoice issued in a different month than the subscription's start/end month?

I'm not too sure about the grain you chose for the fct table. I think Kimball's idea is to go with the most atomic grain (invoice_id in this scenario), but I'm leaning towards one row per subscription_id per month as the requirement states "representing our customer subscriptions over time". Let me know if you think otherwise

Could you write up a dim_month.sql model using the date fields from stg_subskribe__subscriptions and stg_subskribe__invoices? Please also feel free to create a macro if it's easier. Once done, add your assumptions/caveats to the submission file

Do not flatten the two orphan accounts into one "Unknown" value for canonical_company_id - fill the placeholder with some meaningful and distinct values

I think dim_subscription should be modelled as a type 2 SCD. given previous id has been given, it shows a clear continuity pattern. In the SCD, subscription_id can be the PK and renewed_subscription (or something) similar can be the durable key. what do you think?

Create the fact table based on your understanding of the problem and our discussion.

Create relevant description and basic tests for my models

I'm thinking if we really need to separate account from customer and have 2 dim tables. Given company to account is already a 1-1 mapping - would it be easier to have one customer table for simplicity? maybe add this to the assumption and state that we'll need to separate them if this assumption no longer holds. 