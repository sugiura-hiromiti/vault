---
created: 250129 11:50:14
updated: 250419 20:00:03
tags:
  - sql
  - window_functions
aliases:
  - sql_operation_order
id: applenote9
---

**you can’t use window functions in** WHERE**, because the logical order of operations in an SQL query is completely different from the SQL syntax. The** [**logical order of operations in SQL**](https://blog.jooq.org/2016/12/09/a-beginners-guide-to-the-true-order-of-sql-operations/) **is:**
1. FROM, JOIN
2. WHERE
3. GROUP BY
4. aggregate functions
5. HAVING
6. window functions
7. SELECT
8. DISTINCT
9. UNION/INTERSECT/EXCEPT
10. ORDER BY
11. OFFSET
12. LIMIT/FETCH/TOP