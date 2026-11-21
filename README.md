# Banking Analytics | SQL + GenAI Case Study

> A retail banking analytics project built with MySQL to investigate customer balances, branch performance, transaction behaviour, loan repayment risk, fixed-deposit maturity, and cross-selling opportunities.

## Project overview

This project analyses the `Banking_System` relational database from the perspective of a Data Analyst at a retail bank. The goal is to translate business questions into SQL, validate the results, and interpret the findings in a way that can support banking management decisions.

The work is based on an **academic case study provided by my institute**. My contribution was the SQL implementation, query debugging and validation, analytical interpretation, and presentation of the findings.

## Business context

Bank management needs a clearer view of:
- High-balance customers and deposit relationships.
- Branches holding the largest balances in active accounts.
- Monthly transaction volumes and values.
- Accounts with no recent activity.
- Multiple account ownership and inter-account fund flows.
- Loan portfolio quality and late-payment risk.
- Fixed deposits approaching maturity.
- Potential cross-selling opportunities.

## Dataset and database

The project uses the MySQL database `Banking_System`, containing eight interconnected tables and approximately 8,200 records, as described in the institute-provided case study.

| Table | Purpose |
|---|---|
| `branches` | Bank branch details and locations |
| `customers` | Customer profile and KYC information |
| `accounts` | Customer accounts, status, branch, and balance |
| `cards` | Debit and credit cards linked to accounts |
| `transactions` | Account ledger entries and transaction channels |
| `loans` | Loan principal, tenure, interest rate, and status |
| `loan_payments` | EMI due dates, payment dates, principal and interest paid |
| `fixed_deposits` | Fixed-deposit principal, rate, maturity date, and maturity value |

**Data conventions**
- Currency: INR (₹).
- Dataset snapshot date: **1 November 2026**.
- Date-dependent analysis uses `2026-11-01` for reproducibility rather than `CURDATE()`.
- Internal transfers are represented by two ledger entries (`Transfer Out` and `Transfer In`). Do not add both sides when calculating unique transferred value.
- Outstanding loan principal = `principal_amount - SUM(principal_paid)`.
- `fixed_deposits.maturity_amount` already includes interest earned.

## Business questions and analysis

### Core case-study questions

| # | Business question | SQL techniques |
|---:|---|---|
| 1 | Find the top 10 customers by total balance across all their accounts. | Joins, aggregation, sorting |
| 2 | Find the top 5 branches by total balance held in Active accounts. | Joins, filtering, aggregation |
| 3 | Show monthly transaction count and total amount for each transaction type. | Date functions, grouping |
| 4 | Find Active accounts with no transactions in the last 12 months. | `NOT EXISTS`, date filtering |
| 5 | List customers with more than one open account and their combined balance. | `GROUP BY`, `HAVING` |
| 6 | Find the top 10 pairs of accounts by total amount transferred between them. | Self-join, aggregation |
| 7 | Calculate total principal, amount repaid, and outstanding principal for each loan type. | `LEFT JOIN`, aggregation |
| 8 | Calculate late-payment rate by loan type and identify loans with at least three late payments. | Conditional aggregation, `CASE`, `HAVING` |
| 9 | List fixed deposits maturing in the next six months and calculate the interest each will earn. | Date functions, calculations |
| 10 | Find customers with an Active or Defaulted loan who have no fixed deposit. | `NOT EXISTS`, multi-table analysis |

### Additional analysis

The project also includes two additional analyses:
- **Transaction frequency:** Average days between consecutive transactions for each account using `LAG()`.
- **Channel mix:** Transaction count, transaction amount, and transaction share by account type and channel.

## Bonus SQL challenges

The case study includes five bonus challenges:
1. Recompute account running balances using a window function and compare them with `balance_after`.
2. Calculate average days between consecutive transactions using `LAG()`.
3. Identify transfers greater than three times the sender's average transfer amount.
4. For Defaulted loans, compare EMIs due by the snapshot date with EMIs actually paid.
5. Build a transaction-channel mix report for each account type.

## SQL concepts demonstrated

- Filtering, sorting, and conditional logic
- Aggregate functions, `GROUP BY`, and `HAVING`
- `INNER JOIN` and `LEFT JOIN`
- Self-joins
- Subqueries and Common Table Expressions (CTEs)
- `EXISTS` and `NOT EXISTS`
- Date functions and date-boundary handling
- Conditional aggregation with `CASE`
- Window functions, including `LAG()`, `SUM() OVER`, and `FIRST_VALUE()`
- Analytical validation and reconciliation

## Tools

- **MySQL** — relational database querying and analysis
- **MySQL Workbench** — SQL development and query execution
- **GenAI assistant** — schema-aware query explanation, debugging support, alternative approaches, and result interpretation
- **PowerPoint** — presentation of business questions, methods, outputs, and insights

## How GenAI was used

GenAI was used as an assistant during the analytical workflow, not as a substitute for validating the SQL. The database schema and relationships were supplied as context before requesting query help.

Use cases included:
- Understanding table relationships and business requirements.
- Drafting and explaining SQL approaches.
- Debugging syntax and logical errors.
- Reviewing joins and aggregations to reduce double counting.
- Exploring CTE and window-function approaches.
- Interpreting query outputs in business terms.

Final queries and results should be checked against the database and schema. GenAI-generated SQL can be incorrect if the schema, assumptions, or business definitions are misunderstood.

## Key analytical observations

The analysis surfaced several areas for management discussion:
- Customer and branch balance rankings can help identify important deposit relationships, but **account balance is not the same as profitability**.
- Transfer In and Transfer Out are paired ledger records; summing both sides would overstate unique transfer value.
- The Car Loan category had the highest late-payment rate in the analysed output (**16.67%**), while Personal Loans had the lowest (**9.42%**).
- Channel preferences differed by account type: Branch was the most-used channel for Current and Savings accounts in the analysed output, while Net Banking led for Salary accounts.
- Fixed-deposit maturity information can support timely customer outreach and liquidity planning.
- A customer may have multiple qualifying loans, so loan-record counts and distinct-customer counts should be reported separately where relevant.

These are descriptive findings from this dataset, not proof of causation or a complete measure of bank performance. Further analysis is needed before operational or credit decisions.

## Repository structure

```text
banking-analytics-sql-case-study/
├── README.md
├── .gitignore
├── Banking_Analytics_SQL_Project.sql
├── diagrams/
│   └── banking_eer_diagram.png
├── outputs/
│   └── query_results/
└── presentation/
    └── (optional presentation PDF)
```

Add the SQL file, diagram, selected outputs, and presentation only if you have permission to share them. Do not commit customer personal information, credentials, or confidential institutional material.

## How to run

1. Install MySQL Server and MySQL Workbench (or another compatible MySQL client).
2. Obtain the authorised dataset SQL script supplied with the case study.
3. Execute the dataset script to create `Banking_System` and its tables.
4. Select the database:

   ```sql
   USE Banking_System;
   ```

5. Open `Banking_Analytics_SQL_Project.sql` and execute the queries.
6. Check date filters against the project snapshot date, `2026-11-01`.

The dataset creation script is not included unless its redistribution is explicitly permitted.

## Limitations and validation notes

- Results describe the supplied dataset and its 1 November 2026 snapshot; they are not live banking data.
- A high account balance does not establish customer profitability or lifetime value.
- Paired transfer ledger entries require careful treatment to avoid double counting.
- The running-balance reconciliation infers an opening balance from the first available transaction. It checks consistency across the available ledger rather than independently proving the original opening balance.
- The Defaulted-loan EMI comparison depends on how scheduled but unpaid instalments are represented in `loan_payments`. If unpaid instalments do not have rows, the table alone cannot establish every EMI due.
- Recommendations should be validated with additional business context, policy constraints, and risk controls.

## Learning reflection

**Biggest SQL challenge:** Understanding the relationships between the eight tables and writing queries that combine joins, aggregations, subqueries, and window functions without introducing duplicate counts or incorrect totals.

**How GenAI assisted:** It helped clarify the schema and business questions, explain SQL logic, debug errors, compare query approaches, and translate query outputs into business interpretations. I treated its suggestions as drafts and validated the final logic against the schema and data.

**Query-optimization lesson:** Aggregate detail records at the correct grain before joining them to other tables when a one-to-many relationship could multiply rows. Also consider indexes on frequently filtered and joined columns, and validate execution plans before assuming an optimization improves performance.

**Business insight that stood out:** The Car Loan category had the highest late-payment rate in the analysed output, at 16.67%, compared with 9.42% for Personal Loans. This suggests a segment worth investigating further, but the rates alone do not explain why the difference exists.

## Attribution

This project is based on the **“SQL + GenAI Mini Project: Banking Analytics”** academic case study provided by my institute. The case study defines the business scenario, database schema, core questions, bonus challenges, and evaluation expectations. The SQL development, query validation, additional analysis, and interpretation presented in this repository represent my project work.

---

*This repository is an academic portfolio project created to demonstrate practical SQL querying and analytical thinking. It is not affiliated with or endorsed by any real bank.*
