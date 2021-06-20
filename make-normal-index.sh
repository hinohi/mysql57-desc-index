#!/bin/bash

set -eu -o pipefail

mysql_args="-uroot -p1234 -hmysql57d"

mysql $mysql_args << EOL
DROP DATABASE IF EXISTS normal_index;
CREATE DATABASE normal_index;
USE normal_index;

CREATE TABLE tbl (
    id int primary key auto_increment,
    col1 int,
    col2 int
) ENGINE = InnoDB;
EOL

seq 1 10000 | while read col1; do
    m2=$(($RANDOM / 1000))
    (
        echo "INSERT INTO tbl (col1, col2) VALUES ($col1, 0)";
        seq 1 "$m2" | while read col2; do
            echo ",($col1, $col2)"
        done;
        echo ';'
    ) | mysql $mysql_args normal_index
done

mysql $mysql_args normal_index << EOL
ALTER TABLE tbl
    ADD INDEX i_tbl_col1_col2 (col1, col2),
    ADD INDEX i_tbl_col2 (col2)
;
EOL
