#!/bin/bash
SCRIPT_FLOW_BACKUP_SERVER_DIR=${SCRIPT_FLOW_BACKUP_SERVER_DIR:-`pwd`}
SCRIPTS_DIR=${SCRIPTS_DIR:-$SCRIPT_FLOW_BACKUP_SERVER_DIR/../..}
. ../../../conf/conf

echo
print_time_tag

BACKUP_EXCLUDE_PARAM=" \
  --exclude $JOBTRACKER_DIR/logs \
  --exclude $NAMENODE_DIR/logs \
  --exclude $TASKTRACKER_DIR/logs \
  --exclude $DATANODE_DIR/logs \
  --exclude $HADOOP_DATA_DIR/data01 \
  --exclude $HADOOP_DATA_DIR/data02 \
  --exclude $HADOOP_DATA_DIR/data03 \
  --exclude $HADOOP_DATA_DIR/data04 \
  --exclude $HADOOP_DATA_DIR/data05 \
  --exclude $HADOOP_DATA_DIR/data06 \
  --exclude $HADOOP_DATA_DIR/data07 \
  --exclude $HADOOP_DATA_DIR/data08 \
  --exclude $HADOOP_DATA_DIR/data09 \
  --exclude $HADOOP_DATA_DIR/data10 \
  --exclude $HADOOP_DATA_DIR/data11 \
  --exclude $HADOOP_DATA_DIR/data12 \
  --exclude $BACKUP_SERVER_DATA_DIR"
tar $BACKUP_EXCLUDE_PARAM -zcf $BACKUP_SERVER_DATA_DIR/backup-${HADOOP_PLATFORM}_$SERVER_IP-$BACKUP_TIME.tar.gz $HADOOP_WORK_DIR/*
if [ $? -eq 0 ]
then
  touch $BACKUP_SERVER_DATA_DIR/$BACKUP_TIME.done
fi

rm -f $BACKUP_SERVER_DATA_DIR/backup-${HADOOP_PLATFORM}_$SERVER_IP-${DEL_DAY}*.tar.gz
rm -f $BACKUP_SERVER_DATA_DIR/${DEL_DAY}*.done
