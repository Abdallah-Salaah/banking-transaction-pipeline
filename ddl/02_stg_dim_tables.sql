-- STAGING (mirrors source + audit columns)
CREATE TABLE stg_transactions (
    txn_id NUMBER, step NUMBER(5), txn_type VARCHAR2(20), amount NUMBER(18,2),
    name_orig VARCHAR2(20), old_balance_orig NUMBER(18,2), new_balance_orig NUMBER(18,2),
    name_dest VARCHAR2(20), old_balance_dest NUMBER(18,2), new_balance_dest NUMBER(18,2),
    is_fraud NUMBER(1), is_flagged_fraud NUMBER(1),
    load_date TIMESTAMP, batch_id NUMBER
);

-- DIMENSIONS
CREATE TABLE dim_account (
    account_sk     NUMBER PRIMARY KEY,
    account_id     VARCHAR2(20) NOT NULL,
    account_type   VARCHAR2(10),            -- CUSTOMER / MERCHANT
    insert_date    TIMESTAMP,
    update_date    TIMESTAMP,
    batch_id       NUMBER
);

CREATE TABLE dim_transaction_type (
    txn_type_sk    NUMBER PRIMARY KEY,
    txn_type_code  VARCHAR2(20) NOT NULL,
    txn_type_desc  VARCHAR2(100),
    debits_origin  CHAR(1),                 -- 'Y' = origin balance decreases
    insert_date    TIMESTAMP,
    update_date    TIMESTAMP,
    batch_id       NUMBER
);

CREATE TABLE dim_date (
    date_sk NUMBER PRIMARY KEY, date_actual DATE, day NUMBER(2), month NUMBER(2),
    quarter NUMBER(1), year NUMBER(4), weekday_name VARCHAR2(15), weekend_flag CHAR(1),
    insert_date TIMESTAMP, update_date TIMESTAMP, batch_id NUMBER
);


-- ????? ?????? ???????? (-1) ??????? ???????? ???????? ??????
INSERT INTO dim_account (account_sk, account_id, account_type, batch_id) VALUES (-1, 'UNKNOWN', 'UNKNOWN', -1);
INSERT INTO dim_date (date_sk, date_actual, batch_id) VALUES (-1, TO_DATE('1900-01-01', 'YYYY-MM-DD'), -1);
INSERT INTO dim_transaction_type (txn_type_sk, txn_type_code, debits_origin, batch_id) VALUES (-1, 'UNKNOWN', 'N', -1);

-- ????? ??????? ?????? ??????? ?????????
INSERT INTO dim_transaction_type (txn_type_code, txn_type_desc, debits_origin, insert_date, batch_id)
SELECT 'CASH_IN', 'Money deposited into account', 'N', SYSTIMESTAMP, 0 FROM dual UNION ALL
SELECT 'CASH_OUT', 'Money withdrawn from account', 'Y', SYSTIMESTAMP, 0 FROM dual UNION ALL
SELECT 'TRANSFER', 'Money sent to another account', 'Y', SYSTIMESTAMP, 0 FROM dual UNION ALL
SELECT 'PAYMENT', 'Payment made to merchant', 'Y', SYSTIMESTAMP, 0 FROM dual UNION ALL
SELECT 'DEBIT', 'Direct debit from account', 'Y', SYSTIMESTAMP, 0 FROM dual;

COMMIT;
SELECT * FROM dim_transaction_type;
