CREATE TABLE bank_src.transactions (
    txn_id           NUMBER ,
    step             NUMBER(5),
    txn_type         VARCHAR2(20),   -- CSV column "type"
    amount           NUMBER(18,2),
    name_orig        VARCHAR2(20),
    old_balance_orig NUMBER(18,2),
    new_balance_orig NUMBER(18,2),
    name_dest        VARCHAR2(20),
    old_balance_dest NUMBER(18,2),
    new_balance_dest NUMBER(18,2),
    is_fraud         NUMBER(1),
    is_flagged_fraud NUMBER(1),
    CONSTRAINT pk_bank_src_txn PRIMARY KEY (txn_id)
);

   SELECT COUNT(*), SUM(amount), SUM(is_fraud) FROM bank_src.transactions;