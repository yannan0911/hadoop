#!/bin/sh
SCRIPT_FLOW_DIR=${SCRIPT_FLOW_DIR:-`pwd`}
SCRIPTS_DIR=${SCRIPTS_DIR:-$SCRIPT_FLOW_DIR/..}
. ../../conf/conf

cd $SCRIPTS_DIR
COMMAND='ps aux | grep -E "TaskTracker" | grep -v grep | awk "{print \$2}" | xargs kill -9;sleep 5;'
COMMAND=$COMMAND'sudo -u work /search/work/hadoop-envir/hadoop-tasktracker/bin/start-tasktracker.sh;sleep 60;'
sh ssh.sh "$COMMAND" $ALL_LIST_INPUT
cd - > /dev/null 2>&1
