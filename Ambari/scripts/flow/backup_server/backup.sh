#!/bin/bash
SCRIPT_FLOW_BACKUP_SERVER_DIR=${SCRIPT_FLOW_BACKUP_SERVER_DIR:-`pwd`}
SCRIPTS_DIR=${SCRIPTS_DIR:-$SCRIPT_FLOW_BACKUP_SERVER_DIR/../..}
. ../../../conf/conf

set -u
echo
print_time_tag
BACK_DONE="$BACKUP_SERVER_DATA_DIR/$BACKUP_TIME.done"
BACK_TAR="$BACKUP_SERVER_DATA_DIR/backup-${HADOOP_PLATFORM}_$SERVER_IP-$BACKUP_TIME.tar.gz"
rm -f $BACK_DONE $BACK_TAR

case $PLATFORM_TYPE in
  1)
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
    tar $BACKUP_EXCLUDE_PARAM -zcf $BACK_TAR $HADOOP_WORK_DIR/*
    if [ $? -eq 0 ]
    then
      touch $BACK_DONE
    else
      sleep 300
      tar $BACKUP_EXCLUDE_PARAM -zcf $BACK_TAR $HADOOP_WORK_DIR/*
      if [ $? -eq 0 ]
      then
        touch $BACK_DONE
      else
        MAIL_CONTENT="$MAIL_CONTENT TAR"
      fi
    fi

    rm -f $BACKUP_SERVER_DATA_DIR/backup-${HADOOP_PLATFORM}_$SERVER_IP-${DEL_DAY}*.tar.gz
    rm -f $BACKUP_SERVER_DATA_DIR/${DEL_DAY}*.done
  ;;
  2)
    rm -rf $TMP_DIR/${BACKUP_FILE_TAG}_*
    CHECK_TAG=0
    PS_LIST=$(ps aux | grep -E "$KEY_WORD_AMBARI_SERVER|$KEY_WORD_KERBEROS")
    CHECK=$(echo "$PS_LIST" | grep "$KEY_WORD_AMBARI_SERVER" | grep -v grep)
    if [ -n "$CHECK" ]
    then
      postgre_dump $PG_PASSWORD_AMBARI $PG_USER_AMBARI $PG_DATABASE_AMBARI
      postgre_dump $PG_PASSWORD_AMBARIRCA $PG_USER_AMBARIRCA $PG_DATABASE_AMBARIRCA

      if [ $CHECK_TAG -ne 0 ]
      then
        MAIL_CONTENT="$MAIL_CONTENT PG_DUMP"
      fi
    fi

    CHECK=$(echo "$PS_LIST" | grep "$KEY_WORD_KERBEROS" | grep -v grep)
    if [ -n "$CHECK" ]
    then
      $KDB5_UTIL dump $TMP_DIR/$KRB_DUMP_FILE
      if [ ! -f $TMP_DIR/$KRB_DUMP_FILE_OK ]
      then
        MAIL_CONTENT="$MAIL_CONTENT KDB5_DUMP"
      fi

      cp -a $KRB_ROOT_DIR $TMP_DIR/${BACKUP_FILE_TAG}_$KRB_DIR_NAME
      cp -a $KRB_ETC_CONF $TMP_DIR/${BACKUP_FILE_TAG}_$KRB_DIR_NAME
      if [ $? -ne 0 ]
      then
        MAIL_CONTENT="$MAIL_CONTENT CP_KRB_FILE"
      fi
    fi

    tar zcf $BACK_TAR $TMP_DIR/${BACKUP_FILE_TAG}_*
    if [ $? -eq 0 ]
    then
      touch $BACK_DONE
    else
      MAIL_CONTENT="$MAIL_CONTENT TAR_KRB_FILE"
    fi

    rm -f $BACKUP_SERVER_DATA_DIR/backup-${HADOOP_PLATFORM}_$SERVER_IP-${DEL_DAY}*.tar.gz
    rm -f $BACKUP_SERVER_DATA_DIR/${DEL_DAY}*.done
  ;;
  *)
    MAIL_CONTENT="$MAIL_CONTENT PLATFORM_TYPE"
  ;;
esac

if [ -n "${MAIL_CONTENT// /}" ]
then
  mail_tool "backup error" "$MAIL_CONTENT"
fi