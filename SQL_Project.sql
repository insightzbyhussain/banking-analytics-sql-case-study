/*
# PROJECT OVERVIEW
You are a Data Analyst at a retail bank. Your mission is to analyze how customers use the bank's accounts,
cards, loans, and fixed deposits, and help management understand deposits, transaction behavior, loan quality, and
cross-selling opportunities. You will explore the Banking_System database containing 8 interconnected tables and
use both SQL and GenAI tools for analysis, debugging, optimization, and interpretation.

# BUSINESS SCENARIO
The bank's management team wants insights into customer behavior and portfolio health. Your role is to analyze the data and
help answer key questions like: Who are our most valuable customers? Which branches hold the most deposits?
How is money moving between accounts? How healthy is the loan book? Which customers are good targets for fixed deposits or loans?
*/


/*
MOHD HUSSAIN KHAN
*/

-- Using banking_system database as a default schema
USE banking_system;

-- Q1. Find the top 10 customers by total balance across all their accounts.
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(a.balance) AS total_balance
FROM
    accounts a
        JOIN
    customers c ON a.customer_id = c.customer_id
GROUP BY c.customer_id
ORDER BY total_balance DESC
LIMIT 10;


-- Q2. Find the top 5 branches by total balance held in Active accounts.
SELECT 
    b.branch_id,
    b.branch_name,
    SUM(a.balance) AS total_balance,
    a.status
FROM
    branches b
        JOIN
    accounts a ON a.branch_id = b.branch_id
WHERE
    status = 'Active'
GROUP BY b.branch_id , b.branch_name
ORDER BY total_balance DESC
LIMIT 5;


-- Q3. Show the monthly transaction count and total amount for each transaction type.
SELECT 
    YEAR(transaction_date) AS transaction_year,
    MONTH(transaction_date) AS transaction_month,
    transaction_type,
    COUNT(transaction_id) AS total_transaction,
    SUM(amount) AS total_amount
FROM
    transactions
GROUP BY YEAR(transaction_date) , MONTH(transaction_date) , transaction_type
ORDER BY transaction_year , transaction_month , total_transaction;


-- Q4. Find Active accounts with no transactions in the last 12 months.
SELECT 
    a.account_id,
    a.account_number,
    a.customer_id,
    a.account_type,
    a.balance,
    a.status
FROM
    accounts a
WHERE
    a.status = 'Active'
        AND NOT EXISTS( SELECT 
            1
        FROM
            transactions t
        WHERE
            t.account_id = a.account_id
                AND t.transaction_date > '2025-11-01');


-- ==========================================================================================================================
/*
AARYAN
*/

-- Q5. List customers who hold more than one open account, with their combined balance.
SELECT 
    customer_id,
    COUNT(account_id) AS 'total_accounts',
    SUM(balance) AS 'total_balance'
FROM
    accounts
WHERE
    status = 'Active'
GROUP BY customer_id
HAVING COUNT(account_id) > 1;


-- Q6. Find the top 10 pairs of accounts by total amount transferred between them.
SELECT 
    t_out.account_id AS from_account,
    t_out.related_account_id AS to_account,
    SUM(t_out.amount) AS total_transferred
FROM
    transactions t_out
        JOIN
    transactions t_in ON t_out.account_id = t_in.related_account_id
        AND t_out.related_account_id = t_in.account_id
        AND t_out.transaction_date = t_in.transaction_date
        AND t_out.amount = t_in.amount
WHERE
    t_out.transaction_type = 'Transfer Out'
        AND t_in.transaction_type = 'Transfer In'
GROUP BY t_out.account_id , t_out.related_account_id
ORDER BY total_transferred DESC
LIMIT 10;


-- Q7. Calculate total principal, amount repaid, and outstanding principal for each loan type.
SELECT
    l.loan_type,
    SUM(l.principal_amount) AS total_principal,
    SUM(COALESCE(lp.total_repaid, 0)) AS amount_repaid,
    SUM(l.principal_amount)
        - SUM(COALESCE(lp.total_repaid, 0)) AS outstanding_principal
FROM loans AS l
LEFT JOIN (
    SELECT
        loan_id,
        SUM(principal_paid) AS total_repaid
    FROM loan_payments
    GROUP BY loan_id
) AS lp
    ON l.loan_id = lp.loan_id
GROUP BY l.loan_type
ORDER BY outstanding_principal DESC;


-- ==========================================================================================================================
/*
IRSHAD
*/

-- Q8. Find the late-payment rate for each loan type, and list loans with 3 or more late payments.
SELECT l.loan_type,
		COUNT(p.payment_id)  total_payments,
		SUM(CASE WHEN payment_status = 'Late' THEN 1
        ELSE 0
    END) AS late_payments,
		ROUND(SUM(CASE WHEN payment_status = 'Late' THEN 1
            ELSE 0
        END) * 100.0 / COUNT(p.payment_id),
        2
    )  late_payment_rate
FROM loans l
INNER JOIN loan_payments p
    ON l.loan_id = p.loan_id
	GROUP BY l.loan_type;


-- Q9. List fixed deposits maturing in the next 6 months with the interest each will earn.
SELECT fd_id,customer_id principal_amount,interest_rate,start_date,maturity_date,
    DATEDIFF(maturity_date, CURDATE())  days_to_maturity,
    maturity_amount,
    ROUND(maturity_amount - principal_amount,
        2
    )  interest_earned
FROM fixed_deposits
WHERE maturity_date BETWEEN CURDATE()
    AND DATE_ADD(CURDATE(), INTERVAL 6 MONTH)
ORDER BY maturity_date;


-- Q10. Find customers with an Active or Defaulted loan who have no fixed deposit.
SELECT DISTINCT  c.customer_id,c.first_name,c.last_name,l.loan_type,
    l.status AS loan_status
FROM customers c
INNER JOIN loans l
    ON c.customer_id = l.customer_id
WHERE l.status IN ('Active', 'Defaulted')
AND NOT EXISTS (
    SELECT 1
    FROM fixed_deposits fd
    WHERE fd.customer_id = c.customer_id
);

-- ==========================================================================================================================
/*
BONUS CHALLENGES QUESTIONS
*/

-- Q1). Recompute each account's running balance with a window function and check it against balance_after.
WITH transaction_movements AS (
    SELECT
        account_id,
        transaction_id,
        transaction_date,
        transaction_type,
        amount,
        balance_after,
        CASE
            WHEN transaction_type IN ('Deposit', 'Transfer In')
                THEN amount
            WHEN transaction_type IN ('Withdrawal', 'Transfer Out')
                THEN -amount
            ELSE 0
        END AS balance_change
    FROM transactions
),
balance_calculation AS (
    SELECT
        *,
        FIRST_VALUE(balance_after - balance_change) OVER (
            PARTITION BY account_id
            ORDER BY transaction_date, transaction_id
        ) AS inferred_opening_balance,

        SUM(balance_change) OVER (
            PARTITION BY account_id
            ORDER BY transaction_date, transaction_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_change
    FROM transaction_movements
)
SELECT
    account_id,
    transaction_id,
    transaction_date,
    balance_after,
    ROUND(inferred_opening_balance + cumulative_change, 2)
        AS calculated_balance,
    ROUND(
        balance_after - (inferred_opening_balance + cumulative_change), 2
    ) AS balance_difference,
    CASE
        WHEN ABS(
            balance_after - (inferred_opening_balance + cumulative_change)
        ) < 0.01 THEN 'MATCH'
        ELSE 'MISMATCH'
    END AS reconciliation_status
FROM balance_calculation
ORDER BY account_id, transaction_date, transaction_id;


-- Q2). Find the average number of days between consecutive transactions for each account using LAG().
WITH transaction_gaps AS (
    SELECT
        account_id,
        transaction_date,
        LAG(transaction_date) OVER (
            PARTITION BY account_id
            ORDER BY transaction_date, transaction_id
        ) AS previous_transaction_date
    FROM transactions
)
SELECT
    account_id,
    ROUND(
        AVG(
            DATEDIFF(transaction_date, previous_transaction_date)
        ), 2
    ) AS avg_days_between_transactions
FROM transaction_gaps
WHERE previous_transaction_date IS NOT NULL
GROUP BY account_id
ORDER BY avg_days_between_transactions;


-- Q3). Find transfers that are more than 3 times the sender's average transfer amount (subquery).
WITH sender_average AS (
    SELECT
        account_id,
        AVG(amount) AS avg_transfer_amount
    FROM transactions
    WHERE transaction_type = 'Transfer Out'
    GROUP BY account_id
)
SELECT
    t.transaction_id,
    t.account_id AS sender_account,
    t.related_account_id AS receiver_account,
    t.transaction_date,
    t.amount AS transfer_amount,
    ROUND(s.avg_transfer_amount, 2) AS avg_transfer_amount,
    ROUND(s.avg_transfer_amount * 3, 2) AS threshold_amount
FROM transactions t
JOIN sender_average s
    ON t.account_id = s.account_id
WHERE t.transaction_type = 'Transfer Out'
  AND t.amount > 3 * s.avg_transfer_amount
ORDER BY t.amount DESC;


-- Q4). For Defaulted loans, compare the number of EMIs due so far with the number actually paid.
-- BONUS 4: DEFAULTED LOAN EMI ANALYSIS

SELECT
    l.loan_id,
    l.customer_id,
    l.loan_type,
    l.principal_amount,
    COUNT(
        CASE
            WHEN lp.due_date <= '2026-11-01'
            THEN lp.payment_id
        END
    ) AS emis_due,

    COUNT(
        CASE
            WHEN lp.due_date <= '2026-11-01'
             AND lp.payment_date IS NOT NULL
             AND lp.payment_date <= '2026-11-01'
            THEN lp.payment_id
        END
    ) AS emis_actually_paid,

    COUNT(
        CASE
            WHEN lp.due_date <= '2026-11-01'
             AND (
                 lp.payment_date IS NULL
                 OR lp.payment_date > '2026-11-01'
             )
            THEN lp.payment_id
        END
    ) AS unpaid_emis

FROM loans l
LEFT JOIN loan_payments lp
    ON l.loan_id = lp.loan_id
WHERE l.status = 'Defaulted'
GROUP BY
    l.loan_id,
    l.customer_id,
    l.loan_type,
    l.principal_amount
ORDER BY unpaid_emis DESC;


-- Q5. Build a channel mix report (ATM, UPI, Branch, and so on) for each account type.
SELECT
    a.account_type,
    t.channel,
    COUNT(t.transaction_id) AS total_transactions,
    ROUND(SUM(t.amount), 2) AS total_transaction_amount,
    ROUND(
        COUNT(t.transaction_id) * 100.0 /
        SUM(COUNT(t.transaction_id)) OVER (
            PARTITION BY a.account_type
        ), 2
    ) AS transaction_percentage
FROM accounts AS a
INNER JOIN transactions AS t
    ON a.account_id = t.account_id
GROUP BY
    a.account_type,
    t.channel
ORDER BY
    a.account_type,
    total_transactions DESC;


/* 
# LEARNING REFLECTION

1. What was your biggest SQL challenge?
Ans)	My biggest challenge was understanding table relationships
		and writing complex queries involving multiple JOINs,
		aggregations, subqueries, and window functions. Debugging
		queries and validating their outputs also required careful
		attention.

2. How did GenAI assist your problem-solving?
Ans)	GenAI helped me understand project requirements, business
		problems, database schema, table relationships, and SQL
		concepts. It also assisted in debugging queries and
		improving my understanding of different SQL approaches.

3. What query optimization tip did you learn?
Ans)	I learned to aggregate data before joining tables when
		necessary to prevent duplicate calculations and incorrect
		totals. I also learned the importance of indexing columns
		frequently used in JOIN, WHERE, and ORDER BY operations.

4. What business insight surprised you most?
Ans)	The Car Loan category had the highest late-payment rate
		at 16.67%, while Personal Loans had the lowest at 9.42%.
		I also observed different channel preferences across
		account types, showing that customers do not use banking
		channels uniformly.
*/