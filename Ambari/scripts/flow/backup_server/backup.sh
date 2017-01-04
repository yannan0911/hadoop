#!/bin/bash
SCRIPT_FLOW_BACKUP_SERVER_DIR=${SCRIPT_FLOW_BACKUP_SERVER_DIR:-`pwd`}
SCRIPTS_DIR=${SCRIPTS_DIR:-$SCRIPT_FLOW_BACKUP_SERVER_DIR/../..}
. ../../../conf/conf

echo
print_time_tag

tar --exclude $JOBTRACKER_DIR/logs --exclude $NAMENODE_DIR/logs --exclude $BACKUP_SERVER_DATA_DIR -zcf $BACKUP_SERVER_DATA_DIR/backup-$HADOOP_PLATFORM-$BACKUP_TIME.tar.gz $HADOOP_WORK_DIR
if [ $? -eq 0 ]
then
  touch $BACKUP_SERVER_DATA_DIR/$BACKUP_TIME.done
fi

rm -f $BACKUP_SERVER_DATA_DIR/backup-$HADOOP_PLATFORM-${DEL_DAY}*.tar.gz
rm -f $BACKUP_SERVER_DATA_DIR/${DEL_DAY}*.done
