# Findings: Customer Retention & Revenue Analysis

## Headline
About one in three customers (33.8%) has not ordered in 90+ days, but most of them never placed a second order. The revenue at stake sits mainly with 571 lapsed repeat buyers, whose value is spread across many accounts rather than a few large ones.

## Key findings

**1. 33.8% of customers are at risk.**
1,463 of 4,333 customers have had no order in 90+ days (reference date 2011-12-10). The share is 45.8% at 60 days and 28.4% at 120 days, so it is best reported as a range.

**2. Most at-risk customers never came back.**
892 of the 1,463 (61%) are one-time buyers. 57.2% of one-time buyers are at risk, against 20.6% of repeat buyers, and the ranking holds at every cutoff tested. The at-risk share falls from 57.2% at one invoice to 34.5% at 2-3, 12.1% at 4-9 and 2.1% at 10+. Part of this link is mechanical, since frequent buyers have had more chances to order recently.

**3. Repeat buyers carry the revenue.**
Repeat buyers are 64.0% of customers and 92.3% of the £8.48M revenue. One-time buyers are 36.0% of customers and 7.7% of revenue. The top 10 customers hold 16.45% of revenue and the top 10 products 8.0%, so the business leans more on a few customers than on a few products.

**4. The revenue at risk is broad.**
571 repeat buyers have been silent for 90+ days, with £568,620 of past spend (6.7% of total revenue). It takes 114 of them to reach half of that and 295 to reach 80%. The top 10 hold 11.2%. 62% lapsed 90 to 180 days ago, which is the most recoverable window.

**Other observations**
- At-risk customers have a slightly lower median order value (one-time £235 vs £286, repeat £265 vs £311), but the middle ranges overlap heavily, so order value alone does not identify who will lapse.
- At-risk share across the six largest countries ranges from 28% to 40%, but the differences are within sampling noise, so country is not a reliable predictor.
- The UK is 82.4% of revenue. The Netherlands rests on one account (98% of its revenue) and Ireland on two (98%).

## Recommendations

**1. Focus on the second purchase.**
- *Evidence:* 57.2% of one-time buyers are at risk, against 20.6% of repeat buyers. The biggest drop in at-risk share comes between one and two to three invoices.
- *Action:* an automated follow-up (reorder reminder or small incentive) in the weeks after a first order, before the 90-day mark.
- *Target:* first-time buyers, from about 30 days after their first order.
- *Measure:* the share of first-time buyers who place a second order within 90 days.

**2. Tiered win-back for lapsed repeat buyers.**
- *Evidence:* 571 customers, £568,620 of past spend, spread across many accounts (114 reach 50%).
- *Action:*
  - Personal contact for 79 customers (£198,505, 34.9% of lapsed revenue): top 114 by value, lapsed 180 days or less, and late against their own rhythm where that can be measured.
  - A personalised automated message for the rest of the top 114.
  - A generic email for everyone else.
- *Target:* the tiers above. Tier size is a capacity decision, so shrink the personal tier if staff are limited.
- *Measure:* reactivation rate per tier (an order within 60 days of contact) and revenue per contact.
- *Note:* past spend is not recoverable revenue.

**3. Flag at-risk customers against their own rhythm.**
- *Evidence:* the at-risk share ranges from 28% to 46% depending on the cutoff. Among the 252 lapsed repeat buyers with 3+ order days, 16 (6%) were still within their own usual gap and 107 (42%) were more than three times overdue.
- *Action:* keep a flat 90 days for one-time buyers and for repeat buyers with only two order days. For customers with 3+ order days, flag when days since last order exceeds a multiple of their own usual gap, with a floor. A starting proposal is 2x the usual gap with a 60-day floor. This rule has not been tested.
- *Measure:* compare how many customers each rule flags and, later, how many flagged customers actually return.

These are associations, not causes. The data cannot show that an offer would change behaviour, which is why each recommendation has a measure.

## Limitations
- Rows with no CustomerID (24.9% of rows, 14.7% of merchandise revenue) are excluded, so customer-level results cover identified customers only. Hong Kong disappears from country revenue.
- 39 customers with no valid purchase in the window (0.9%) are excluded.
- Revenue means merchandise revenue, excluding postage and fees.
- Cancellations are dropped. Voided originals were also removed for the four customers with the largest cancelled value that were audited (12346, 16446, 15749, 16029). Smaller cancel-and-reissue cases may remain.
- Cancelled orders are not counted as activity.
- One description is kept per product code. 85123A and 22502 cover two different descriptions.
- The data covers 12 months, so observed gaps skew short and a 90-day rule is crude for slow-cycle buyers.
- A customer's own usual gap is only reliable with 3+ order days. 319 of the 571 lapsed repeat buyers (56%) have just two.
- Past spend is not future value.

## Method
Raw data was loaded unmodified into SQLite, cleaned through one SQL view with six documented rules, and analysed in Pandas. Every decision and reconciliation is in `reports/profiling_notes.md`.
