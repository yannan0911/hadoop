#!/bin/sh
function rsync_backup () {
  PLATFORM=$1
  SERVER=$2
  SERVER_IP=$3

  rsync -aP $SERVER_IP::root$REMOTE_BACKUP_DIR/$BACKUP_TIME.$DONE $DATA_DIR > /dev/null
  if [ $? -eq 0 ];then
    rsync -aP $SERVER_IP::root$REMOTE_BACKUP_DIR/backup-${PLATFORM}_*-$BACKUP_TIME.tar.gz $DATA_DIR
    if [ $? -ne 0 ];then
      MESSAGE="$PLATFORM-$SERVER $MESSAGE"
    fi
  else
    MESSAGE="$PLATFORM-$SERVER $MESSAGE"
  fi
}

function rsync_all_backup () {
  LIST=$1
  grep -Ev '#|^$' $LIST > $TMP_DIR/$PLATFORM_LIST
  LIST=$TMP_DIR/$PLATFORM_LIST
  TOTAL_LINE_NUM=$(wc -l $LIST | awk '{print $1}')
  for line in $(seq $TOTAL_LINE_NUM)
  do
    PLATFORM=$(awk 'NR=='$line'{print $1}' $LIST)
    SERVER=$(awk 'NR=='$line'{print $2}' $LIST)
    SERVER_IP=$(awk 'NR=='$line'{print $3}' $LIST)
    rsync_backup $PLATFORM $SERVER $SERVER_IP
  done
}

function error_alert () {
  if [ -n "${MESSAGE// /}" ]
  then
    ERROR_MESSAGE="[$SMSHEAD][hadoop backup failed $MESSAGE]"
    sh $SENDSMS "$ERROR_MESSAGE"
  fi
}
