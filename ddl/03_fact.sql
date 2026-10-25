CREATE TABLE fact_transactions (
    txn_id             NUMBER PRIMARY KEY,
    step               NUMBER(5),
    date_sk            NUMBER,
    txn_type_sk        NUMBER,
    orig_account_sk    NUMBER,
    dest_account_sk    NUMBER,
    amount             NUMBER(18,2),
    old_balance_orig   NUMBER(18,2),
    new_balance_orig   NUMBER(18,2),
    old_balance_dest   NUMBER(18,2),
    new_balance_dest   NUMBER(18,2),
    is_fraud_source    NUMBER(1),
    balance_check_flag CHAR(1),            -- 'P' (Pass) / 'F' (Fail) / 'N' (Not Applicable)
    row_hash           VARCHAR2(64),       
    insert_date        TIMESTAMP,
    batch_id           NUMBER,
    CONSTRAINT fk_fact_date FOREIGN KEY (date_sk) REFERENCES dim_date(date_sk),
    CONSTRAINT fk_fact_type FOREIGN KEY (txn_type_sk) REFERENCES dim_transaction_type(txn_type_sk),
    CONSTRAINT fk_fact_orig_acc FOREIGN KEY (orig_account_sk) REFERENCES dim_account(account_sk),
    CONSTRAINT fk_fact_dest_acc FOREIGN KEY (dest_account_sk) REFERENCES dim_account(account_sk)
);
