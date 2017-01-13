#!/bin/bash
# 守护进程；
# 当 hadoop 任务际内存占用超过10G时，保存进程列表，杀死进程；
# 当系统实际内存使用率超过95%时，保存进程列表，杀死占用内存最高的进程(除 hadoop 服务外的 work 用户进程)；
# 清理一个月前的列表文件。

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
TMP_DIR=$WORK_DIR/tmp
mkdir -p $HISTORY_DIR $TMP_DIR

HADOOP_NAMENODE='/search/work/hadoop-envir/hadoop-namenode/bin/'
HADOOP_JOBTRACKER='/search/work/hadoop-envir/hadoop-jobtracker/bin/'
HADOOP_DATANODE='/search/work/hadoop-envir/hadoop-datanode/bin'
HADOOP_TASKTRACKER='/search/work/hadoop-envir/hadoop-tasktracker/bin'
CHECK_EXCLUDE="($HADOOP_NAMENODE|$HADOOP_JOBTRACKER|$HADOOP_DATANODE|$HADOOP_TASKTRACKER)"

# 单个任务内存(单位:kb)
TASK_MEM_THRESHOLD='10485760'
# 系统内存使用率阈值(百分比 %)
SYS_MEM_THRESHOLD=95
TIMETAG_NOW=$(date +'%Y%m%d%H%M%S')
TIMETAG_MONTH_AGO=$(date -d '1 month ago' +'%Y%m%d')
PROGRESS_TMP="$TMP_DIR/progress"
PROGRESS_LIST_TMP="$TMP_DIR/progress_list"
PID_TO_KILL_FILE="$TMP_DIR/pid_to_kill"
OLD_HISTORY_FILE="$HISTORY_DIR/progress_*list_$TIMETAG_MONTH_AGO*"

ps aux > $PROGRESS_TMP
ps -ef f > $PROGRESS_LIST_TMP

# 获取系统实际内存使用率超过95%时，占用内存最高的 PID(除 hadoop 服务外的 work 用户进程)；
SYS_MEM_CHECK=$(free -k|awk '/buffers\/cache:/{if($3*100/($3+$4)>'$SYS_MEM_THRESHOLD'){print 1}}')
if [ "$SYS_MEM_CHECK"x == 1x ]
then
  grep '^work' $PROGRESS_TMP | grep -Ev "$CHECK_EXCLUDE" | sort -k6 -rn | head -n 1 | \
    awk '{print $2}' > $PID_TO_KILL_FILE
fi

# 获取 hadoop 任务际内存占用超过10G的 PID；
grep '^work' $PROGRESS_TMP | grep -Ev "$CHECK_EXCLUDE" | \
  awk '{if($6>'$TASK_MEM_THRESHOLD'){print $2}}' >> $PID_TO_KILL_FILE

if [ -s $PID_TO_KILL_FILE ]
then
  # 杀死上述整理出的进程
  sort $PID_TO_KILL_FILE | uniq | xargs kill -9
  cp $PROGRESS_TMP "$HISTORY_DIR/progress_list_$TIMETAG_NOW"
  cp $PROGRESS_LIST_TMP "$HISTORY_DIR/progress_tree_list_$TIMETAG_NOW"
  cp $PID_TO_KILL_FILE "$HISTORY_DIR/pid_to_kill_$TIMETAG_NOW"
fi

rm -f $PROGRESS_TMP $PROGRESS_LIST_TMP $PID_TO_KILL_FILE $OLD_HISTORY_FILE
