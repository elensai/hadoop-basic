#!/bin/bash


host_dns=( "hadoop-basic-ss-0.ha-svc.default.svc.cluster.local" "hadoop-basic-ss-1.ha-svc.default.svc.cluster.local" "hadoop-basic-ss-2.ha-svc.default.svc.cluster.local" )

    for i in "${host_dns[@]}"
    do
      echo $i
    done

exit 0 

source /etc/profile

case $1 in
  zkfc)
  zkCli.sh >zk-status.txt <<EOF
    ls /
EOF

  if [ `grep 'hadoop-ha' zk-status.txt | wc -l` -eq 0 ];then
    hdfs zkfc -formatZK
  else
    echo 'zookeeper exsit'
  fi
  ;;

  nnfc)
  if [ ! -d /user/data/hadoop/hdfs/name ];then
    hadoop namenode -format
    ssh $2 "rm -rf /user/data/hadoop/*"
    scp -r /user/data/hadoop/hdfs $2:/user/data/hadoop/
  else
    echo 'nn exsit'
  fi
  ;;

  flink)
  hadoop fs -test -e hdfs://ns/flink/history ; 
  if [ $? -ne 0 ]; then 
    hadoop fs -mkdir -p hdfs://ns/flink/history ; 
  else
    echo 'flink exsit'
  fi
  ;;

  oozie)
  hadoop fs -test -e /user/root/share/lib/* ;
  if [ $? -ne 0 ]; then  
    (oozie-setup.sh prepare-war sharelib create -fs hdfs://ns -locallib $OOZIE_HOME/oozie-sharelib-4.0.0-cdh5.3.6-yarn.tar.gz) && (ooziedb.sh create -sqlfile oozie.sql -run DB Connection && oozied.sh start);
  else
    echo 'oozie exsit'
  fi
  ;;

  spark)
  hadoop fs -test -e hdfs://ns/log/spark/eventlogs ;
  if [ $? -ne 0 ]; then 
    hadoop fs -mkdir -p hdfs://ns/log/spark/eventlogs && hadoop fs -mkdir -p hdfs://ns/spark_jars/ && hadoop fs -put $SPARK_HOME/jars/*  hdfs://ns/spark_jars/;
  else
    echo 'spark exsit'
  fi
  ;;

  *)
    echo 'other'
  ;;
esac

