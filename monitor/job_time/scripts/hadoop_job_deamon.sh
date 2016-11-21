#!/bin/sh
JOB_SCRIPT='hadoop_job_time.sh'
TIME=3
SLEEP=60
CHECK_JOB=0

for i in $(seq $TIME)
do
    CHECK_JOB=$(($CHECK_JOB+$(ps aux | grep "sh $JOB_SCRIPT" | grep -v grep | wc -l)))
    sleep $SLEEP
done

if [ $CHECK_JOB -eq 0 ]
then
    sh $JOB_SCRIPT &
fi