--Creating Tables--
CREATE TABLE items (
    store_id VARCHAR(10) NOT NULL,
    item_id VARCHAR(20) NOT NULL,
    item_category VARCHAR(100),
    item_name VARCHAR(200),
    CONSTRAINT pk_items PRIMARY KEY (store_id, item_id)
);
GO

CREATE TABLE transactions (
    buyer_id INT,
    purchase_time DATETIME2,
    refund_time DATETIME2 NULL,
    refund_item VARCHAR(20),
    store_id VARCHAR(20),
    item_id VARCHAR(20),
    gross_transaction_value INT
);
GO

--Queries--
1. 
SELECT
    FORMAT(purchase_time, 'yyyy-MM') AS purchase_month,
    COUNT(*) AS purchases_count
FROM transactions
WHERE refund_time IS NULL
GROUP BY FORMAT(purchase_time, 'yyyy-MM')
ORDER BY purchase_month;

2.
SELECT COUNT(*) AS stores_with_5plus_orders
FROM (
    SELECT store_id, COUNT(*) AS order_count
    FROM transactions
    WHERE purchase_time >= '2020-10-01'
      AND purchase_time < '2020-11-01'
    GROUP BY store_id
    HAVING COUNT(*) >= 5
) AS x;

3.
SELECT
    store_id,
    MIN(DATEDIFF(MINUTE, purchase_time, refund_time)) AS min_interval_minutes
FROM transactions
WHERE refund_time IS NOT NULL
GROUP BY store_id
ORDER BY store_id;

4.
WITH ordered AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY purchase_time ASC) AS rn
    FROM transactions
)
SELECT store_id, purchase_time, gross_transaction_value, item_id, buyer_id
FROM ordered
WHERE rn = 1
ORDER BY store_id;

5.
WITH first_purchase AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time ASC) AS rn
    FROM transactions
)
SELECT TOP 1
    i.item_name,
    COUNT(*) AS frequency
FROM first_purchase fp
JOIN items i 
    ON fp.store_id = i.store_id AND fp.item_id = i.item_id
WHERE fp.rn = 1
GROUP BY i.item_name
ORDER BY frequency DESC;

6.
--add column
ALTER TABLE transactions
ADD refund_processable BIT;
GO
--update column--
UPDATE transactions
SET refund_processable =
    CASE 
        WHEN refund_time IS NULL THEN 0
        WHEN refund_time <= DATEADD(HOUR, 72, purchase_time) THEN 1
        ELSE 0
    END;
GO
--verify--
SELECT refund_processable, COUNT(*) AS count_rows
FROM transactions
GROUP BY refund_processable;


7.
WITH ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time ASC) AS rn
    FROM transactions
    WHERE refund_time IS NULL
)
SELECT buyer_id, purchase_time, item_id, store_id, rn
FROM ranked
WHERE rn = 2
ORDER BY buyer_id;

8.
WITH ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time ASC) AS rn
    FROM transactions
)
SELECT buyer_id, purchase_time AS second_transaction_time, item_id, store_id
FROM ranked
WHERE rn = 2
ORDER BY buyer_id;
