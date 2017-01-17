#!/bin/sh
SCRIPT_FLOW_DIR=${SCRIPT_FLOW_DIR:-`pwd`}
SCRIPTS_DIR=${SCRIPTS_DIR:-$SCRIPT_FLOW_DIR/..}
. ../../conf/conf

set -u
echo
print_time_tag

case $PLATFORM_TYPE in
  1)
    ADMIN_DIR=root
  ;;
  2)
    ADMIN_DIR=hdfs
  ;;
  *)
    MAIL_CONTENT="$MAIL_CONTENT PLATFORM_TYPE"
  ;;
esac

$HADOOP fs -rmr /user/$ADMIN_DIR/.Trash
USER_TRASH=$($HADOOP fs -ls /user/*/.Trash | grep -v "/user/$ADMIN_DIR/" | awk '{print $NF}' | grep -E '/user/.+/\.Trash/' | xargs)
if [ "${USER_TRASH// /}" ]
then
  $HADOOP fs -rmr $USER_TRASH
fi

if [ -n "${MAIL_CONTENT// /}" ]
then
  mail_tool "clean_trash error" "$MAIL_CONTENT"
fi
