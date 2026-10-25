# 🏦 Enterprise Banking Transaction Pipeline & Automated Fraud Screening Engine

An production-grade, end-to-end Data Engineering pipeline built using **Informatica PowerCenter** and **Oracle SQL**, architected to ingest, transform, and reconcile **750,000+ simulated mobile money records** (derived from the PaySim financial dataset). 

This pipeline replicates core banking compliance architecture, enforcing strict transaction-level balance integrity checks, metadata-driven reconciliation logs, a tamper-evident audit trail, and regulatory PII masking.

---

## 🏗️ End-to-End Architecture & Data Flow

The project isolation is strictly maintained across two dedicated Oracle schemas to mimic a real-world enterprise financial ecosystem:
- **`BANK_SRC`**: Financial Transactional Source (OLTP Simulation).
- **`BANK_DWH`**: Analytical Star Schema Data Warehouse with explicit tablespace isolation.

```text
  [ Raw CSV Data ] ---> [ Python Pandas Sampling ] ---> [ BANK_SRC.transactions ]
                                                                 |
                                                     (Informatica ETL Pipeline)
                                                                 v
                                                    [ BANK_DWH.stg_transactions ]
                                                                 |
                                              +------------------+------------------+

                                              |                                     |
                                     (Dimension Loads)                       (Fact Population)

                                              |                                     |
                                              v                                     v
                                      [ dim_account ]                     [ fact_transactions ]
                                      [ dim_txn_type ]                              |
                                      [ dim_date ]                                  v
                                                                          (Banking Security Layer)
                                                                          • balance_recon_exception
                                                                          • fraud_flags
                                                                          • audit_hash_log
                                                                          • bank_report (PII Masked Access)
```

---

## 🛡️ Key Banking Engineering Features

1. **Transaction-Level Balance Integrity:** Instead of loose aggregate matching, the pipeline validates individual mathematical transitions. For outgoing streams (`TRANSFER`, `CASH_OUT`), it verifies if $Old\_Balance - Amount = New\_Balance$. Anomalies are captured instantly without dropping rows.
2. **Metadata-Driven Reconciliation:** Full source-to-target tracking via a custom reconciliation ledger (`etl_recon_log`), logging row counts and financial amounts across every pipeline milestone.
3. **Automated Fraud Screening:** Embedded rule-based analytic engine mapping transaction types, volumetric limits, and critical balance depletion indicators.
4. **Immutable Audit Trail:** Row-level hashing using native cryptographic functions to produce deterministic signatures. Internal PL/SQL triggers prevent data alteration or deletion post-audit.
5. **PII Masking & RBAC:** Complete Separation of Duties (SoD). Reporting consumers access data through dynamic masking functions (`C1234567` becomes `C12XXXXX`), isolated under a restricted database profile (`bank_report`).

---

## 📈 Operational Performance & Metric Validations

### 1. Data Pipeline Reconciliation Summary
- **Total Records Ingested & Verified:** `750,000` Rows
- **Reconciliation Audit Status:** `3 of 3 Reconciliation Checks Passed (100% Balanced)`
- **Core Security Audit:** `0 Rows contain NULL cryptographic signatures.`

### 2. Fraud Engine Performance Matrices
*   **Recall (Sensitivity Ratio):** `99.6%` (Caught 99.6% of actual malicious transaction profiles)
*   **Precision (Positive Predictive Value):** `5.4%`

> **Engineering Insight on Precision/Recall Trade-Off:** In transactional risk systems, maintaining near-perfect *Recall* is mission-critical to eliminate financial leakages. The low *Precision* ratio reflects standard banking operations—since thousands of clean users legally empty accounts daily. These alarms are securely routed to secondary investigative human-in-the-loop audit tables without breaking pipeline latency.

---

## ⚡ Performance Tuning Benchmarks

To scale execution over a single virtual machine infrastructure, granular performance modifications were benchmarked against a fixed production baseline:

| Optimization Phase | Session Execution Runtime | Cumulative Throughput Improvement |
| :--- | :--- | :--- |
| **Baseline (Normal Load, 10k Commits)** | 14 Min : 22 Sec | Default |
| **+ Bulk Target Loading Enabled** | 04 Min : 51 Sec | ~66.2% |
| **+ Tuned Commit Intervals (50k)** | 03 Min : 18 Sec | ~77.0% |
| **+ DB-Side Inline Joins Overhaul** | 01 Min : 45 Sec | ~87.8% |

*Architectural Bottleneck Note:* The cryptographic sequence (`sp_audit_batch`) loops sequentially to compute the final batch verification fingerprint. Because each hash directly depends on the preceding state, this layer cannot be parallelized—reflecting a real-world design constraint documented in our specifications.

---

## 🧪 The Tamper-Evident Security Proof (Simulation Ledger)

To validate data governance, a privileged insider bypass attack was simulated in our test environment (`/ddl/06_test_defects.sql`):
1. **Direct Attack Attempt:** An unauthorized query attempted to inject a `+$1000` increment directly to an archived record.
2. **Database Level Block:** The operation was immediately terminated by the immutable framework throwing an `ORA-20001` safety exception.
3. **Privileged Escalation & Corruption:** The immutable safety triggers were deliberately disabled to force the malicious update into the database table, followed by re-enabling protection.
4. **Audit Execution Resolution:** Running `EXEC sp_verify_batch(1)` immediately shifted the pipeline status to **`FAIL - DATA CHANGED SINCE LOAD`**, extracting the exact compromised `txn_id`.
5. **Restoration Verification:** Data was rolled back to its historical state, returning the audit validation loop back to **`PASS`**.

---

## 🛠️ Honest Production Limitations & Future Milestones
- **Synthetic Vector Limitations:** Input dates are synthetically projected from hourly logging counters.
- **Sampling Bias:** Sampling strategies locked every available fraud row, naturally inflating baseline precision models compared to broader global trends.
- **Cryptographic Upgrades:** Current lab profiles leverage SHA-1 hashes via native wrappers. Production enterprise migrations should swap directly to SHA-256 (a single-line configuration alteration).
- **Architecture Scalability:** True immutable frameworks demand storing batch fingerprints completely separate from the core environment (e.g., write-once-read-many WORM secure infrastructure).

---

## 🗂️ Repository Directory Blueprint
- `/ddl`: Structured schema migration statements, constraint keys, and triggers.
- `/mappings`: Exported native Informatica XML pipeline workflows.
- `/parameters`: Configuration files managing environmental global attributes.
- `/docs`: Functional design sheets and the architectural flowcharts.
- `/screenshots`: Visual validation captures proving end-to-end execution success.
