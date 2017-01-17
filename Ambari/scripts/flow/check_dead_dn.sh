#!/bin/sh
SCRIPT_FLOW_DIR=${SCRIPT_FLOW_DIR:-`pwd`}
SCRIPTS_DIR=${SCRIPTS_DIR:-$SCRIPT_FLOW_DIR/..}
. ../../conf/conf

echo
print_time_tag

$HADOOP dfsadmin -report > $DFSADMIN_REPORT_TMP
if [ -s $DEAD_DN_LIST_TMP ]
then
  cp -a $DEAD_DN_LIST_TMP{,.$SEC1970}
fi
grep -E '^(Name|Decommission Status|Last contact)' $DFSADMIN_REPORT_TMP | \
  awk '{
    if($0~/^Last contact/) {
      $1=""
      $2=""
      system("date +%s -d \x027"$0"\x027")
      print ""
    }
    else {
      split($NF,content,":")
      printf content[1]" "
    }
  }' | awk '/Normal/{
    if('$SEC1970'-$3>'$THRESHOLD_SECOND') {
      print $1
    }
  }' > $DEAD_DN_LIST_TMP

cd $SCRIPTS_DIR
COMMAND='ps aux|grep -E "TaskTracker|DataNode"|grep -v grep|awk "{print \$2}"|xargs kill -9;sleep 5;'
COMMAND=$COMMAND'sudo -u work /search/work/hadoop-envir/hadoop-datanode/bin/start-datanode.sh;'
COMMAND=$COMMAND'sudo -u work /search/work/hadoop-envir/hadoop-tasktracker/bin/start-tasktracker.sh'
sh ssh.sh "$COMMAND" $DEAD_DN_LIST_TMP
cd - > /dev/null 2>&1
