#!/bin/sh
set -e
set -u
ulimit -n 10000

#settings
SOCKET=/var/lib/mysql/mysql.sock
SYSBENCH=/usr/share/sysbench/tpcc.lua
THREADS="16 32 64 128 256"
CREATEDB=0
TABLES=64
TOTAL_ROWS=400000000
RUNTIME_RW=300
REPORT=5

ROWS=$(($TOTAL_ROWS / $TABLES))

for thread in $THREADS
 do
   $SYSBENCH --mysql-socket=$SOCKET --mysql-user=root --mysql-db=sbt --time=$RUNTIME_RW --threads=$thread --report-interval=5 --tables=20 --scale=100 --db-driver=mysql run

   sleep 60

done
