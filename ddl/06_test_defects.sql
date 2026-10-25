-- Test 1: NEGATIVE AMOUNT -> should be a REJECT
-- Test 1: NEGATIVE AMOUNT -> should be a REJECT
INSERT INTO transactions (step, txn_type, amount, name_orig, old_balance_orig, new_balance_orig,
                          name_dest, old_balance_dest, new_balance_dest, is_fraud, is_flagged_fraud)
VALUES (10, 'TRANSFER', -500, 'CTEST0001', 1000, 1500, 'CTEST0002', 0, 0, 0, 0);

-- Test 2: NULL ORIGIN ACCOUNT -> should be a REJECT
INSERT INTO transactions (step, txn_type, amount, name_orig, old_balance_orig, new_balance_orig,
                          name_dest, old_balance_dest, new_balance_dest, is_fraud, is_flagged_fraud)
VALUES (11, 'PAYMENT', 100, NULL, 1000, 900, 'MTEST0003', 0, 0, 0, 0);

-- Test 3: ACCOUNT NOT IN THE DIMENSION -> should be a WARNING (loaded with key -1)
INSERT INTO transactions (step, txn_type, amount, name_orig, old_balance_orig, new_balance_orig,
                          name_dest, old_balance_dest, new_balance_dest, is_fraud, is_flagged_fraud)
VALUES (12, 'PAYMENT', 100, 'CTEST0004', 1000, 900, 'MTEST0005', 0, 0, 0, 0);

-- Test 4: BALANCE DOESN'T TIE OUT -> should load, flagged 'F', and land in BALANCE_RECON_EXCEPTION
-- (1000 - 100 should leave 900, but the row says 500)
INSERT INTO transactions (step, txn_type, amount, name_orig, old_balance_orig, new_balance_orig,
                          name_dest, old_balance_dest, new_balance_dest, is_fraud, is_flagged_fraud)
VALUES (13, 'CASH_OUT', 100, 'CTEST0006', 1000, 500, 'CTEST0007', 0, 0, 0, 0);

COMMIT;

-- What landed in the error log
SELECT source_key, error_type, error_reason
FROM etl_error_log
WHERE mapping_name = 'm_fact_transactions'
  AND source_key IN (SELECT TO_CHAR(txn_id) FROM stg_transactions
                     WHERE name_orig LIKE 'CTEST%' OR name_orig IS NULL OR name_dest LIKE 'MTEST%' OR name_dest LIKE 'CTEST%')
ORDER BY error_type;

-- The balance failure
SELECT txn_id, expected_balance, actual_balance, difference
FROM balance_recon_exception
WHERE account_id LIKE 'CTEST%';

-- What actually reached the fact table
SELECT txn_id, orig_account_sk, dest_account_sk, balance_check_flag
FROM fact_transactions
WHERE txn_id IN (SELECT txn_id FROM stg_transactions WHERE name_orig LIKE 'CTEST%');

SELECT (SELECT COUNT(*) FROM stg_transactions) AS read_rows,
       (SELECT COUNT(*) FROM fact_transactions) AS loaded_rows,
       (SELECT COUNT(*) FROM etl_error_log
         WHERE mapping_name='m_fact_transactions' AND error_type='REJECT') AS rejected_rows
FROM dual;

   DELETE FROM transactions
   WHERE name_orig LIKE 'CTEST%' OR name_orig IS NULL OR name_dest LIKE 'MTEST%';
   COMMIT;
   
      DELETE FROM balance_recon_exception WHERE account_id LIKE 'CTEST%';
   DELETE FROM etl_error_log WHERE mapping_name = 'm_fact_transactions';
   COMMIT;
