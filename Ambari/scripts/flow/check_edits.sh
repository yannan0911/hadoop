#!/bin/sh
SCRIPT_FLOW_DIR=${SCRIPT_FLOW_DIR:-`pwd`}
SCRIPTS_DIR=${SCRIPTS_DIR:-$SCRIPT_FLOW_DIR/..}
. ../../conf/conf

echo
print_time_tag

cd $EDITS_FILE_DIR
ls -l edits* | \
  awk '{
    if($5>'$EDITS_FILE_SIZE_THRESHOLD') {
      system("sh /opt/mail/sendmail.sh -t '$ADMIN_MAIL' -s \"[Hadoop_Report] "$NF" "($5-($5%(1024*1024)))/1024/1024"MB\" -c \" \" > /dev/null")
    }
  }'
cd - > /dev/null 2>&1
