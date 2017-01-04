#!/bin/sh
SCRIPT_FLOW_DIR=${SCRIPT_FLOW_DIR:-`pwd`}
SCRIPTS_DIR=${SCRIPTS_DIR:-$SCRIPT_FLOW_DIR/..}
. ../../conf/conf

echo
print_time_tag

$HDFS fs -rmr /user/root/.Trash
USER_TRASH=$($HDFS fs -ls /user/*/.Trash | grep -v '/user/root/' | awk '{print $NF}' | grep -E '/user/.+/\.Trash/' | xargs)
if [ "${USER_TRASH// /}" ]
then
  $HDFS fs -rmr $USER_TRASH
fi
