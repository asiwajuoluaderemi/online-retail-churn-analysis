# Profiling & Cleaning Notes

Lab notebook: every check, rule, number and mistake. Conclusions are in `findings.md`.

**Data:** UCI Online Retail, 541,909 rows, 2010-12-01 to 2011-12-09 12:50, 25,900 invoices, 4,372 customers
**Reference date:** 2011-12-10 (last date + 1), dates only

## Status snapshot

| Item | Value |
|---|---|
| Clean rows / customers / products / invoices | 396,321 / 4,333 / 3,659 / 18,396 |
| Clean revenue (merchandise) | £8,480,598.41 |
| At risk at 60 / 90 / 120 days | 45.8% / 33.8% / 28.4% |
| One-time / repeat buyers | 1,559 / 2,774 |
| Lapsed repeat buyers | 571, £568,619.51 past spend |

## 1. Pipeline

| File | Purpose |
|---|---|
| `src/load_data.py` | Load raw Excel into `raw_online_retail`, unmodified |
| `src/run_sql_file.py` | Run any `.sql` file, foreign keys on |
| `sql/00_profile_raw_data.sql` | Profiling queries |
| `sql/01_create_tables.sql` | Empty `customers`, `products`, `orders` with keys and CHECKs |
| `sql/02_clean_data.sql` | `clean_lines` view with all cleaning rules |
| `sql/02b_load_tables.sql` | Fill the three tables from `clean_lines` |
| `sql/03` to `06` | Deliverable queries (tasks 4 to 7) |
| `notebooks/01_data_loading_and_validation.ipynb` | Validation of raw and clean data |
| `notebooks/02_churn_analysis.ipynb` | Pandas analysis and charts |

Rebuild order: `01`, `02`, `02b`. Never run `02b` twice without `01` first.

## 2. Raw data findings and decisions

| Area | Finding | Decision |
|---|---|---|
| Load | The "C" prefix is in `InvoiceNo`, not `CustomerID` | Cancellations found via `InvoiceNo` |
| Countries | Casing clean. EIRE = Ireland, RSA = South Africa | Relabelled |
| Countries | Unspecified and European Community: 0.04% of clean revenue | Keep, exclude from country chart only |
| Countries | 8 customers appear under 2 countries | One country each (rule below) |
| Countries | Hong Kong: 288 rows, none with a customer ID | Absent from country revenue |
| IDs | 135,080 rows (24.9%) have no CustomerID. They are 14.71% of merchandise revenue (14.85% of raw net revenue) | Excluded |
| IDs | NULL-ID lines average about £11.49 against £22.11 for identified lines | Smaller tickets are the main reason the revenue share is below the row share |
| Price | 2 negative ("Adjust bad debt", prefix A), 2,515 zero (40 with IDs) | Removed |
| Price | Max 38,970 is a `C` invoice with StockCode `M` (Manual) | Removed |
| Quantity | +/-80,995 is order 581483 and cancellation C581484 | Named exclusion |
| Cancellations | All 9,288 `C` invoices have negative quantity. 1,336 other negatives are all zero price and no ID | Both rules needed, the second already covered |
| Cancellations | Only 33% of `C` rows have an exact earlier match | Pair matching rejected |
| Fees | AMAZONFEE -221,520, DOT +206,245, M -68,672, POST +66,231 | Excluded |
| Vouchers, DCGS, PADS | Low value, real sales | Kept |

**Country rule:** most distinct invoices, ties to latest invoice, then alphabetical. Only customer 12394 needs the tie-break (Belgium 1 vs Denmark 1, so Denmark). Counting invoices, not lines, matters here.
**Product description rule:** most frequent, ties to latest, then alphabetical. 213 codes (5.8%) have several descriptions, mostly wording only. 85123A (white vs cream) and 22502 (small vs 60 pieces) differ in meaning.

## 3. Cleaning rules and waterfall

| Rule | Removes | Rows removed | Rows left |
|---|---|---:|---:|
| Raw | | | 541,909 |
| 1 | No CustomerID | 135,080 | 406,829 |
| 2 | `C` invoices | 8,905 | 397,924 |
| 3 | Quantity <= 0 (safety guard) | 0 | 397,924 |
| 4 | UnitPrice <= 0 | 40 | 397,884 |
| 5 | POST, DOT, M, C2, D, S, BANK CHARGES, AMAZONFEE, CRUK, B (matched with `UPPER`) | 1,544 | 396,340 |
| 6 | Voided originals: 541431, 581483, 540815, 540818, 570094, 570097 | 19 | 396,321 |
| **Total** | | **145,588** | |

### Cancellation audit

A return after a real sale still counts as activity, so only the `C` row is dropped. A cancel-and-reissue means the original was voided and replaced, so the original is removed too.

| Customer | Pattern | Evidence | Treatment |
|---|---|---|---|
| 12346 | Cancelled in full | 541431 (£77,183.60) and C541433, 16 minutes apart | Remove original |
| 16446 | Cancelled in full | 581483 (£168,469.60) and C581484 | Remove original. One real £2.90 order remains |
| 15749 | Reissue | 540815 and 540818 (£22,998.40) voided by C550456, reissued as 550461 (£21,535.90) | Remove originals. Customer becomes one-time |
| 16029 | Reissue | 570094 and 570097 (£11,816.64) voided by C570556, reissued as 570557 (£7,810.56) | Remove originals. Customer stays repeat |
| 12931 | Ordinary returns | Partial `C` rows, no replacement | Keep originals |

Revenue effect of the last two: £8,515,413.45 to £8,480,598.41 (-£34,815.04). Before the audit, cancelled value was 5.4% of gross (£474k), with two customers making up 52%. Only the largest cancellation customers were audited, so smaller reissues may remain. The remaining overstatement was not recomputed.

## 4. Customers lost in cleaning
4,372 became 4,333: 39 customers (0.9%) have no valid purchase left. 33 cancellation-only, 4 fee-only (15802, 15823, 16742, 17846), 1 zero-price only (13256), 1 cancelled in full (12346). Decision: exclude, since churn needs a completed purchase.

## 5. Deliverable queries

| Query | Result |
|---|---|
| 03 revenue per customer | Total £8,480,598.41, reconciled across orders, customers, products and countries. Top 10 customers £1,394,737.00 (16.45%) |
| 04 top products | Top 10 by revenue £675,644.69 (8.0%). Four products in both top-10 lists. No fees or vouchers |
| 05 revenue by country | 37 countries. UK 82.37%, Netherlands 3.35%, Ireland 3.03%. Netherlands 98% one account, Ireland 98% two |
| 06 last order date | 4,333 rows. Latest valid order 2011-12-09 12:50 |

## 6. Churn analysis log

| Step | Result |
|---|---|
| Days since last order | Min 1, median 51, mean 93.2, max 374, no negatives. Right-skewed |
| Order days / gaps | 16,675 order days, 12,342 gaps (order days, not invoices). Pooled median 28, 75th 58, 90th 111, 95th 155 |
| Per-customer usual gap | Median 52.5, 75th percentile 97.5 (2,774 customers). 1,559 have one order day |
| Cutoff | 90+ days (`>=`). One-time buyers kept separate |
| Status at 90 days | 2,870 active, 1,463 at risk. One-time 667 / 892, repeat 2,203 / 571 |
| Sensitivity (all / repeat / one-time) | 60: 45.8 / 31.6 / 71.1. 90: 33.8 / 20.6 / 57.2. 120: 28.4 / 15.1 / 52.1 |
| Median order value (active vs at risk) | One-time £286 vs £235. Repeat £311 vs £265. 25th-75th ranges: one-time 165-431 vs 138-370, repeat 204-448 vs 159-406. Weak signal |
| By invoice count (1 / 2-3 / 4-9 / 10+) | Customers 1,506 / 1,331 / 1,110 / 386. At risk 57.2 / 34.5 / 12.1 / 2.1%. Link to recency partly mechanical |
| Country | Top-six at-risk shares 27.6% to 40.0%, within sampling noise |
| Segments | One-time 1,559 (36.0%), £651,748 (7.7%). Repeat 2,774 (64.0%), £7,828,850 (92.3%) |
| At-risk revenue | £937,999 (11.1%). Lapsed repeat £568,620 (6.7%) |
| Lapsed repeat | 571 customers. 114 hold 50%, 295 hold 80%, top 10 hold 11.2%. Recency bands 90-120 / 121-180 / 181-270 / 271+: 160 / 193 / 165 / 53 |
| Own-gap check | 319 of 571 (56%, £226,320) have only two order days. Reliable group 252: 16 (6%) not yet past own gap, 107 (42%) over 3x overdue, median ratio 2.6 |
| Personal-contact tier | Top 114 by value, lapsed 180 days or less, overdue where 3+ order days: 79 customers, £198,505 (34.9%) |
| 17850 | 34 invoices on two days (Dec 1 and 2, 2010): a burst, not a rhythm |
| 16446 | One invoice of £2.90 (2011-05-18): one-time, at risk |

## 7. Mistakes caught
- A leftover `LIMIT 10` in query 03 produced a partial merge. The £8,515,413.45 reconciliation caught it.
- The first cleaning missed cancel-and-reissue cases (15749, 16029). Found by checking the largest cancelled values, then rebuilt.
- The overdue ratio looked reliable, but 56% of lapsed customers rested on a single gap. A guard was added.
- Superseded figures: 75-customer tier (pre-guard), 79 / 236 overdue counts (included single-gap customers), 16.9% top-10 lapsed (included 15749), and all pre-rebuild totals (£8,515,413.45, 396,338 rows, 572 lapsed repeat).

## 8. Limitations
Same list as `findings.md`.
