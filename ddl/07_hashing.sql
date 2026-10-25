ALTER FUNCTION fn_batch_hash COMPILE;
ALTER PROCEDURE sp_audit_batch COMPILE;
ALTER PROCEDURE sp_verify_batch COMPILE;

SELECT object_name, status FROM user_objects
WHERE object_name IN ('FN_HASH','FN_BATCH_HASH','SP_AUDIT_BATCH','SP_VERIFY_BATCH');

SELECT column_name FROM user_tab_columns
WHERE table_name = 'FACT_TRANSACTIONS' AND column_name = 'ROW_HASH';

SELECT DISTINCT batch_id FROM fact_transactions;

SET SERVEROUTPUT ON
EXEC sp_audit_batch(1);
EXEC sp_verify_batch(1);
SELECT COUNT(*) FROM fact_transactions WHERE row_hash IS NULL;   -- must be 0

-- Hashed fact rows can't be changed or deleted
CREATE OR REPLACE TRIGGER trg_fact_immutable
BEFORE UPDATE OR DELETE ON fact_transactions
FOR EACH ROW
BEGIN
  IF :OLD.row_hash IS NOT NULL THEN
    RAISE_APPLICATION_ERROR(-20001, 'FACT_TRANSACTIONS rows are immutable after audit hashing');
  END IF;
END;
/

-- The hash log is append-only
CREATE OR REPLACE TRIGGER trg_audit_log_immutable
BEFORE UPDATE OR DELETE ON audit_hash_log
BEGIN
  RAISE_APPLICATION_ERROR(-20002, 'AUDIT_HASH_LOG is append-only');
END;
/


-- Try to cheat the normal way: blocked by the trigger
UPDATE fact_transactions SET amount = amount + 1000
 WHERE txn_id = (SELECT MIN(txn_id) FROM fact_transactions);
-- expect ORA-20001

-- Simulate a privileged insider bypassing the trigger
ALTER TRIGGER trg_fact_immutable DISABLE;
UPDATE fact_transactions SET amount = amount + 1000
 WHERE txn_id = (SELECT MIN(txn_id) FROM fact_transactions);
COMMIT;
ALTER TRIGGER trg_fact_immutable ENABLE;

EXEC sp_verify_batch(1);
-- expect: 1 row altered, batch hash match NO, RESULT: FAIL

-- Find the exact row
SELECT txn_id FROM vw_fact_hash_calc WHERE stored_hash <> calc_hash;

-- Restore it
ALTER TRIGGER trg_fact_immutable DISABLE;
UPDATE fact_transactions SET amount = amount - 1000
 WHERE txn_id = (SELECT MIN(txn_id) FROM fact_transactions);
COMMIT;
ALTER TRIGGER trg_fact_immutable ENABLE;

EXEC sp_verify_batch(1);   -- back to PASS




UPDATE fact_transactions SET amount = amount + 1000
WHERE txn_id = (SELECT MIN(txn_id) FROM fact_transactions);

ALTER TRIGGER trg_fact_immutable DISABLE;

UPDATE fact_transactions SET amount = amount + 1000
WHERE txn_id = (SELECT MIN(txn_id) FROM fact_transactions);

COMMIT;
ALTER TRIGGER trg_fact_immutable ENABLE;


SET SERVEROUTPUT ON
EXEC sp_verify_batch(1);

ALTER TRIGGER trg_fact_immutable DISABLE;

UPDATE fact_transactions SET amount = amount - 1000
WHERE txn_id = (SELECT MIN(txn_id) FROM fact_transactions);

COMMIT;
ALTER TRIGGER trg_fact_immutable ENABLE;
