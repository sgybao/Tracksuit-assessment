# SUBMISSION.md

## Running the project

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python3 load_raw_data.py
dbt deps
dbt build
```

That builds everything end to end: staging, then the intermediate layer, then
the dim/fact marts, then the GRR reporting model, plus the full test suite.

## Key assumptions

- Voided invoices don't count as revenue anywhere in the project.
- Revenue is recognised in the month the invoice was issued, not spread out across the subscription term.
- "Today" for the reporting model is the last month with real invoice activity, not the actual current date. This also isn't the same as the latest month in the calendar dimension, which deliberately runs into the future to cover contracts that are still active.
- GRR groups customers by their current size segment, since we only have one snapshot of that data and can't know what segment they were in 12 months ago.
- Renewal chains are grouped together using the account id as the durable key, since every account so far has exactly one clean chain of renewals with no branching. If an account ever churned and later came back as a separate new deal, this would incorrectly treat it as a continuation of the same chain.
- The two accounts with no matching HubSpot company are kept rather than dropped, each given its own placeholder customer, and they show up as their own "Unknown" segment in the GRR report instead of being excluded, so the numbers still tie back to the fact table.
- The brief asks for a dim/fact pair; this ships three small dimensions (`dim_customer`, `dim_subscription`, `dim_month`) plus one fact, not a literal single pair. `dim_subscription` and `dim_month` earn their keep on current need alone: the fact's grain key otherwise has no table describing it, and `dim_month` replaces what would otherwise be an ad hoc date spine duplicated in two places.
- A separate `dim_account` was considered and deliberately not built. Company and billing account are conceptually distinct entities, but they collapse 1:1 in this dataset today, so a dedicated table would only be justified by a hypothetical future (a company with more than one billing account) rather than any current need. Billing attributes (`account_id`, `billing_currency`, `account_created_at`, `is_unmapped`) live on `dim_customer` instead.

## Data quality issues found and how they were handled

- Subscription status is sometimes inconsistent with contract dates - a few are marked expired while still within their contract dates. Activity is worked out from the start and end dates instead.
- Invoice timing doesn't always match subscription coverage exactly - some are billed close to a month in advance, and a handful land just after the subscription ends. Coverage and billed revenue are kept as separate things rather than assumed to match.
- Two accounts reference a HubSpot company that doesn't exist anywhere, even accounting for merge history. They're a small share of revenue, so rather than dropping them they're kept with their own placeholder identity so nothing gets lost or double-counted.
