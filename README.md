# mysql57-desc-index

```
docker compose up
```

```
docker run -ti --rm --network=mysql57-desc-index_default mysql:5.7 mysql -uroot -p1234 -hmysql57d
```

```
mysql> use normal_index;
mysql> select count(1) from tbl;
+----------+
| count(1) |
+----------+
|   167522 |
+----------+
1 row in set (0.02 sec)
```

order by はどちら向きも利く。

```
mysql> explain select * from tbl where col1=100 order by col2 desc limit 1;
+----+-------------+-------+------------+------+-----------------+-----------------+---------+-------+------+----------+--------------------------+
| id | select_type | table | partitions | type | possible_keys   | key             | key_len | ref   | rows | filtered | Extra                    |
+----+-------------+-------+------------+------+-----------------+-----------------+---------+-------+------+----------+--------------------------+
|  1 | SIMPLE      | tbl   | NULL       | ref  | i_tbl_col1_col2 | i_tbl_col1_col2 | 5       | const |   28 |   100.00 | Using where; Using index |
+----+-------------+-------+------------+------+-----------------+-----------------+---------+-------+------+----------+--------------------------+
1 row in set, 1 warning (0.00 sec)

mysql> explain select * from tbl where col1=100 order by col2 limit 1;
+----+-------------+-------+------------+------+-----------------+-----------------+---------+-------+------+----------+--------------------------+
| id | select_type | table | partitions | type | possible_keys   | key             | key_len | ref   | rows | filtered | Extra                    |
+----+-------------+-------+------------+------+-----------------+-----------------+---------+-------+------+----------+--------------------------+
|  1 | SIMPLE      | tbl   | NULL       | ref  | i_tbl_col1_col2 | i_tbl_col1_col2 | 5       | const |   28 |   100.00 | Using where; Using index |
+----+-------------+-------+------------+------+-----------------+-----------------+---------+-------+------+----------+--------------------------+
1 row in set, 1 warning (0.00 sec)
```

```
mysql> explain select col1, max(col2) from tbl group by col1 limit 100;
+----+-------------+-------+------------+-------+---------------+-------+---------+------+------+----------+--------------------------+
| id | select_type | table | partitions | type  | possible_keys | key   | key_len | ref  | rows | filtered | Extra                    |
+----+-------------+-------+------------+-------+---------------+-------+---------+------+------+----------+--------------------------+
|  1 | SIMPLE      | tbl   | NULL       | range | i_tlb         | i_tlb | 5       | NULL |  561 |   100.00 | Using index for group-by |
+----+-------------+-------+------------+-------+---------------+-------+---------+------+------+----------+--------------------------+
1 row in set, 1 warning (0.01 sec)

mysql> explain select col1, min(col2) from tbl group by col1 limit 100;
+----+-------------+-------+------------+-------+---------------+-------+---------+------+------+----------+--------------------------+
| id | select_type | table | partitions | type  | possible_keys | key   | key_len | ref  | rows | filtered | Extra                    |
+----+-------------+-------+------------+-------+---------------+-------+---------+------+------+----------+--------------------------+
|  1 | SIMPLE      | tbl   | NULL       | range | i_tlb         | i_tlb | 10      | NULL |  561 |   100.00 | Using index for group-by |
+----+-------------+-------+------------+-------+---------------+-------+---------+------+------+----------+--------------------------+
1 row in set, 1 warning (0.00 sec)
```

これはなぜか早い

```
mysql> explain select * from tbl as t1 where t1.col2=(select max(t2.col2) from tbl as t2 where t2.col1=t1.col1) order by id desc limit 10;
+----+--------------------+-------+------------+-------+---------------+------------+---------+----------------------+------+----------+-------------+
| id | select_type        | table | partitions | type  | possible_keys | key        | key_len | ref                  | rows | filtered | Extra       |
+----+--------------------+-------+------------+-------+---------------+------------+---------+----------------------+------+----------+-------------+
|  1 | PRIMARY            | t1    | NULL       | index | NULL          | PRIMARY    | 4       | NULL                 |   10 |   100.00 | Using where |
|  2 | DEPENDENT SUBQUERY | t2    | NULL       | ref   | i_tbl_col1    | i_tbl_col1 | 5       | normal_index.t1.col1 |   17 |   100.00 | NULL        |
+----+--------------------+-------+------------+-------+---------------+------------+---------+----------------------+------+----------+-------------+
2 rows in set, 2 warnings (0.00 sec)
```

これはだめ

```
mysql> explain select * from tbl as t1 where t1.col2=(select col2 from tbl as t2 where t2.col1=t1.col1 order by col2 desc limit 1) order by id desc limit 10;
+----+--------------------+-------+------------+-------+----------------------------+-----------------+---------+----------------------+------+----------+------------------------------------------+
| id | select_type        | table | partitions | type  | possible_keys              | key             | key_len | ref                  | rows | filtered | Extra                                    |
+----+--------------------+-------+------------+-------+----------------------------+-----------------+---------+----------------------+------+----------+------------------------------------------+
|  1 | PRIMARY            | t1    | NULL       | index | NULL                       | PRIMARY         | 4       | NULL                 |   10 |   100.00 | Using where                              |
|  2 | DEPENDENT SUBQUERY | t2    | NULL       | ref   | i_tbl_col1,i_tbl_col1_col2 | i_tbl_col1_col2 | 5       | normal_index.t1.col1 |   16 |   100.00 | Using where; Using index; Using filesort |
+----+--------------------+-------+------------+-------+----------------------------+-----------------+---------+----------------------+------+----------+------------------------------------------+
2 rows in set, 2 warnings (0.00 sec)
mysql> explain select * from tbl as t1 where t1.col2=(select col2 from tbl as t2 where t2.col1=t1.col1 order by col2 limit 1) order by id desc limit 10;
+----+--------------------+-------+------------+-------+----------------------------+-----------------+---------+----------------------+------+----------+------------------------------------------+
| id | select_type        | table | partitions | type  | possible_keys              | key             | key_len | ref                  | rows | filtered | Extra                                    |
+----+--------------------+-------+------------+-------+----------------------------+-----------------+---------+----------------------+------+----------+------------------------------------------+
|  1 | PRIMARY            | t1    | NULL       | index | NULL                       | PRIMARY         | 4       | NULL                 |   10 |   100.00 | Using where                              |
|  2 | DEPENDENT SUBQUERY | t2    | NULL       | ref   | i_tbl_col1,i_tbl_col1_col2 | i_tbl_col1_col2 | 5       | normal_index.t1.col1 |   16 |   100.00 | Using where; Using index; Using filesort |
+----+--------------------+-------+------------+-------+----------------------------+-----------------+---------+----------------------+------+----------+------------------------------------------+
2 rows in set, 2 warnings (0.00 sec)
```
