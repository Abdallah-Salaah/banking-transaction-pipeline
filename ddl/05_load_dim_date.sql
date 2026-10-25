INSERT INTO dim_date (date_sk, date_actual, day, month, quarter, year,
                      weekday_name, weekend_flag, insert_date, batch_id)
WITH date_range AS (
    SELECT TO_DATE('2025-01-01', 'YYYY-MM-DD') + (LEVEL - 1) AS d
    FROM dual
    CONNECT BY LEVEL <= 31
)
SELECT TO_NUMBER(TO_CHAR(d, 'YYYYMMDD')),
       d,
       TO_NUMBER(TO_CHAR(d, 'DD')),
       TO_NUMBER(TO_CHAR(d, 'MM')),
       TO_NUMBER(TO_CHAR(d, 'Q')),
       TO_NUMBER(TO_CHAR(d, 'YYYY')),
       TRIM(TO_CHAR(d, 'Day', 'NLS_DATE_LANGUAGE=ENGLISH')),
       CASE WHEN TO_CHAR(d, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') IN ('SAT','SUN') THEN 'Y' ELSE 'N' END,
       SYSTIMESTAMP,
       0
FROM date_range;
COMMIT;

SELECT COUNT(*), MIN(date_actual), MAX(date_actual) FROM dim_date;
