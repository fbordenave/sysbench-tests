#!/bin/sh
set -e
set -u
ulimit -n 10000

#settings
SOCKET=/var/lib/mysql/mysql.sock
SYSBENCH=/bin/sysbench
THREADS="16 32 64 128 256"
#THREADS="128"
CREATEDB=0
TABLES=64
TOTAL_ROWS=400000000
RUNTIME_RW=1800
REPORT=5

ROWS=$(($TOTAL_ROWS / $TABLES))

if [ "$CREATEDB" != "0" ]
 then
  #create sbtest database
  mysql -S $SOCKET -u root -e "DROP DATABASE IF EXISTS sbtest"
  mysql -S $SOCKET -u root -e "CREATE DATABASE sbtest"

  #create and fill oltp table(s)
  if [ $TABLES -gt 1 ]
   then
     $SYSBENCH /usr/share/sysbench/tests/include/oltp_legacy/parallel_prepare.lua --oltp_tables_count=$TABLES --oltp-table-size=$ROWS --num-threads=$TABLES --mysql-socket=$SOCKET --mysql-user=root run
   else
     $SYSBENCH /usr/share/sysbench/tests/include/oltp_legacy/oltp.lua --oltp_tables_count=$TABLES --oltp-table-size=$ROWS --num-threads=1 --mysql-socket=$SOCKET --mysql-user=root prepare
  fi

else

 #warmup buffer pool
 echo -n "warmup ... "
  PIDLIST=""
  for i in `seq $TABLES` ; do
    (time mysql -S $SOCKET -e "SELECT AVG(id) FROM sbtest$i FORCE KEY (PRIMARY)" sbtest)  2>&1   &
    PIDLIST="$PIDLIST $!"
  done
  wait $PIDLIST
  echo "done"
 sleep 10

fi

#run the benchmark
for thread in $THREADS
 do

  if [ $RUNTIME_RW -gt 0 ]
   then

     $SYSBENCH /usr/share/sysbench/oltp_read_only.lua --tables=$TABLES --table-size=$ROWS --rand-seed=42 --rand-type=uniform --threads=$thread --report-interval=$REPORT --mysql-socket=$SOCKET --time=$RUNTIME_RW --mysql-user=root --percentile=99 run | tee -a sysbench.rw.$thread.res

   fi
   sleep 60

done
