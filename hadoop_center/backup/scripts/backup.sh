#!/bin/bash
SCRIPTS_DIR=${SCRIPTS_DIR:-`pwd`}
. ../conf/conf

rsync_all_backup $PLATFORM_LIST_FILE
error_alert

#del
if [ $NOW_HOUR == "0" ];then
    rm -f $DATA_DIR/backup-*$DEL_TIME*
    rm -f $DATA_DIR/$DEL_TIME*
fi
