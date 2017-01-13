#!/bin/bash
DIR_TAG=$(dirname $0 | awk '{if(substr($0,0,1)=="."){print 1}}')
if [ $DIR_TAG -eq 1 ]
then
  WORK_DIR="$(pwd)/$(dirname $0)/.."
else
  WORK_DIR="$(dirname $0)/.."
fi
SCRIPTS_DIR=$WORK_DIR/scripts
LOGS_DIR=$WORK_DIR/logs
HISTORY_DIR=$LOGS_DIR/history
mkdir -p $HISTORY_DIR $LOGS_DIR

HADOOP_NAMENODE='/search/work/hadoop-envir/hadoop-namenode/bin/'
HADOOP_JOBTRACKER='/search/work/hadoop-envir/hadoop-jobtracker/bin/'
HADOOP_DATANODE='/search/work/hadoop-envir/hadoop-datanode/bin'
HADOOP_TASKTRACKER='/search/work/hadoop-envir/hadoop-tasktracker/bin'
CHECK_EXCLUDE="$HADOOP_NAMENODE|$HADOOP_JOBTRACKER|$HADOOP_DATANODE|$HADOOP_TASKTRACKER"

TIMETAG_NOW=$(date +'%Y%m%d%H%M%S')
TIMETAG_MONTH_AGO=$(date -d '1 month ago' +'%Y%m%d')
PROGRESS_TO_KILL_FILE="$HISTORY_DIR/progress_to_kill_$TIMETAG_NOW"
OLD_HISTORY_FILE="$HISTORY_DIR/progress_to_kill_$TIMETAG_MONTH_AGO*"
IP=$(/sbin/ip a | sed -rn '/scope global eth0/s/.*inet[[:blank:]]([0-9.]+)\/.*/\1/gp' | head -n 1)

TIMETAG_NOW=$(date +'%Y%m%d%H%M%S')
TIMETAG_MONTH_AGO=$(date -d '1 month ago' +'%Y%m%d')

ps -ef | awk --posix '{
  if($1=="work" && $0!~/'${CHECK_EXCLUDE//\//\\/}'/ && $5!~/[0-9]{2}:[0-9]{2}/) {
    print $0 >> "'$PROGRESS_TO_KILL_FILE'"
    print $2
    system("sh /opt/mail/sendmail.sh -c \" \" -s \"[Hadoop_Report] '$IP' check_timeout_job\" -t \"yannan@sogou-inc.com\" > /dev/null 2>&1")
  }
}' #| xargs kill -9

rm -f $OLD_HISTORY_FILE
