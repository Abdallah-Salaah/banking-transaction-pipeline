CREATE TABLE etl_batch_log (
    batch_id NUMBER PRIMARY KEY, workflow_name VARCHAR2(100), start_time TIMESTAMP,
    end_time TIMESTAMP, rows_read NUMBER, rows_loaded NUMBER, rows_rejected NUMBER, status VARCHAR2(20)
);
CREATE TABLE etl_error_log (
    error_id     NUMBER PRIMARY KEY,
    batch_id     NUMBER,
    mapping_name VARCHAR2(100),
    source_key   VARCHAR2(100),
    error_reason VARCHAR2(500),
    error_type   VARCHAR2(10),
    error_date   TIMESTAMP
);

CREATE SEQUENCE seq_error_id START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE OR REPLACE TRIGGER trg_error_id
BEFORE INSERT ON etl_error_log
FOR EACH ROW
WHEN (NEW.error_id IS NULL)
BEGIN
    SELECT seq_error_id.NEXTVAL INTO :NEW.error_id FROM dual;
END;
/
CREATE TABLE etl_recon_log (
    batch_id NUMBER, table_name VARCHAR2(50), source_count NUMBER, target_count NUMBER,
    source_sum NUMBER(20,2), target_sum NUMBER(20,2), status VARCHAR2(10)
);

-- Banking-specific
CREATE TABLE balance_recon_exception (
    txn_id NUMBER, batch_id NUMBER, txn_type VARCHAR2(20), account_id VARCHAR2(20),
    expected_balance NUMBER(18,2), actual_balance NUMBER(18,2), difference NUMBER(18,2),
    detected_date TIMESTAMP
);
CREATE TABLE fraud_flags (
    txn_id NUMBER, batch_id NUMBER, rule_name VARCHAR2(50), flag_date TIMESTAMP
);
CREATE TABLE audit_hash_log (
    batch_id NUMBER, table_name VARCHAR2(50), row_count NUMBER,
    batch_hash VARCHAR2(64), created_date TIMESTAMP
);

SELECT table_name FROM user_tables ORDER BY table_name;

SELECT table_name, tablespace_name FROM user_tables;