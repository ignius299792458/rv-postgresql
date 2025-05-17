# 🗂️ **Simplified Table Samples**

## 📄 `customers`

| customer_id | first_name | referred_by |
| ----------- | ---------- | ----------- |
| C1          | Alice      | NULL        |
| C2          | Bob        | C1          |
| C3          | Charlie    | C1          |
| C4          | Diana      | NULL        |

---

## 📄 `bank_accounts`

| account_id | account_number | customer_id |
| ---------- | -------------- | ----------- |
| A1         | 111111         | C1          |
| A2         | 222222         | C2          |
| A3         | 333333         | NULL        |

---

## 📄 `transactions`

| transaction_id | account_id | amount |
| -------------- | ---------- | ------ |
| T1             | A1         | 100.00 |
| T2             | A1         | 50.00  |
| T3             | A2         | 200.00 |
| T4             | A3         | 300.00 |

---

# 🔗 JOIN SCENARIOS WITH OUTPUTS

---

## 1️⃣ **INNER JOIN** (Only matching `customer_id` ↔ `bank_accounts`)

```sql
SELECT c.first_name, b.account_number
FROM customers c
INNER JOIN bank_accounts b ON c.customer_id = b.customer_id;
```

## 🔍 Result

| first_name | account_number |
| ---------- | -------------- |
| Alice      | 111111         |
| Bob        | 222222         |

➡️ Only customers who have a **bank account** appear.

---

## 2️⃣ **LEFT JOIN** (All customers + their accounts if any)

```sql
SELECT c.first_name, b.account_number
FROM customers c
LEFT JOIN bank_accounts b ON c.customer_id = b.customer_id;
```

## 🔍 Result

| first_name | account_number |
| ---------- | -------------- |
| Alice      | 111111         |
| Bob        | 222222         |
| Charlie    | NULL           |
| Diana      | NULL           |

➡️ All customers show up; accounts may be null if none.

---

## 3️⃣ **RIGHT JOIN** (All accounts + owner names if any)

```sql
SELECT c.first_name, b.account_number
FROM customers c
RIGHT JOIN bank_accounts b ON c.customer_id = b.customer_id;
```

## 🔍 Result

| first_name | account_number |
| ---------- | -------------- |
| Alice      | 111111         |
| Bob        | 222222         |
| NULL       | 333333         |

➡️ All accounts show up; customer may be null.

---

## 4️⃣ **FULL JOIN** (All customers and all accounts, matched if possible)

```sql
SELECT c.first_name, b.account_number
FROM customers c
FULL JOIN bank_accounts b ON c.customer_id = b.customer_id;
```

## 🔍 Result

| first_name | account_number |
| ---------- | -------------- |
| Alice      | 111111         |
| Bob        | 222222         |
| Charlie    | NULL           |
| Diana      | NULL           |
| NULL       | 333333         |

➡️ Everyone and every account appears.

---

## 5️⃣ **CROSS JOIN** (Every customer with every account — ⚠️ huge)

```sql
SELECT c.first_name, b.account_number
FROM customers c
CROSS JOIN bank_accounts b;
```

## 🔍 Result (4 × 3 = 12 rows)

| first_name | account_number |
| ---------- | -------------- |
| Alice      | 111111         |
| Alice      | 222222         |
| Alice      | 333333         |
| Bob        | 111111         |
| Bob        | 222222         |
| Bob        | 333333         |
| Charlie    | 111111         |
| Charlie    | 222222         |
| Charlie    | 333333         |
| Diana      | 111111         |
| Diana      | 222222         |
| Diana      | 333333         |

➡️ Not useful unless generating all combos.

---

## 6️⃣ **SELF JOIN** (Who referred whom)

```sql
SELECT c1.first_name AS referred, c2.first_name AS referrer
FROM customers c1
LEFT JOIN customers c2 ON c1.referred_by = c2.customer_id;
```

## 🔍 Result

| referred | referrer |
| -------- | -------- |
| Alice    | NULL     |
| Bob      | Alice    |
| Charlie  | Alice    |
| Diana    | NULL     |

➡️ Shows internal relationships.

---

## 7️⃣ **LATERAL JOIN** (Sum of transactions per account)

```sql
SELECT b.account_number, t.total_amount
FROM bank_accounts b
LEFT JOIN LATERAL (
    SELECT SUM(amount) AS total_amount
    FROM transactions t
    WHERE t.account_id = b.account_id
) t ON TRUE;
```

## 🔍 Result

| account_number | total_amount |
| -------------- | ------------ |
| 111111         | 150.00       |
| 222222         | 200.00       |
| 333333         | 300.00       |

➡️ Allows subqueries per row. Efficient for aggregates.

---

## 8️⃣ **NATURAL JOIN** (Only works if both tables have `customer_id` and you want to join on it)

```sql
SELECT * FROM customers
NATURAL JOIN bank_accounts;
```

➡️ Joins using all **columns with same names**. Dangerous unless very intentional.

---

# 🧭 Summary Table

| JOIN Type    | When to Use                       | Rows Returned                  |
| ------------ | --------------------------------- | ------------------------------ |
| INNER JOIN   | Only matched rows                 | C1 & C2                        |
| LEFT JOIN    | All from left, matched from right | C1, C2, C3, C4                 |
| RIGHT JOIN   | All from right, matched from left | A1, A2, A3                     |
| FULL JOIN    | All rows from both sides          | All customers + accounts       |
| CROSS JOIN   | All combinations (cartesian)      | 12 rows (4 × 3)                |
| SELF JOIN    | Compare rows within same table    | Referrals                      |
| LATERAL JOIN | Subquery per row (aggregates)     | Total transactions per account |
| NATURAL JOIN | Quick join on same-column names   | Use with caution               |

---
