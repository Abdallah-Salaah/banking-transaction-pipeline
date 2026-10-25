CREATE OR REPLACE FUNCTION fn_mask_account (p_id IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC IS
BEGIN
  IF p_id IS NULL THEN RETURN NULL; END IF;
  RETURN SUBSTR(p_id, 1, 1) || RPAD('*', GREATEST(LENGTH(p_id) - 4, 1), '*') || SUBSTR(p_id, -3);
END;
/
SELECT fn_mask_account('C1231006815') FROM dual;

CREATE OR REPLACE VIEW vw_txn_masked AS
SELECT f.txn_id,
       d.date_actual                       AS txn_date,
       tt.txn_type_code                    AS txn_type,
       fn_mask_account(oa.account_id)      AS origin_account,
       fn_mask_account(da.account_id)      AS dest_account,
       f.amount,
       f.balance_check_flag,
       f.is_fraud_source                   AS known_fraud,
       CASE WHEN EXISTS (SELECT 1 FROM fraud_flags ff WHERE ff.txn_id = f.txn_id)
            THEN 'Y' ELSE 'N' END          AS rule_flagged
FROM fact_transactions f
JOIN dim_date d              ON d.date_sk = f.date_sk
JOIN dim_transaction_type tt ON tt.txn_type_sk = f.txn_type_sk
JOIN dim_account oa          ON oa.account_sk = f.orig_account_sk
JOIN dim_account da          ON da.account_sk = f.dest_account_sk;

CREATE OR REPLACE VIEW vw_daily_summary AS
SELECT d.date_actual AS txn_date, tt.txn_type_code AS txn_type,
       COUNT(*) AS txns, SUM(f.amount) AS total_amount,
       SUM(CASE WHEN f.balance_check_flag = 'F' THEN 1 ELSE 0 END) AS balance_failures,
       SUM(f.is_fraud_source) AS known_fraud
FROM fact_transactions f
JOIN dim_date d              ON d.date_sk = f.date_sk
JOIN dim_transaction_type tt ON tt.txn_type_sk = f.txn_type_sk
GROUP BY d.date_actual, tt.txn_type_code;

SELECT COUNT(*) FROM vw_txn_masked;

GRANT SELECT ON vw_txn_masked   TO bank_report;
GRANT SELECT ON vw_daily_summary TO bank_report;