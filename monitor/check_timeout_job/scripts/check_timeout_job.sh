#!/bin/bash
set -u
job="job.txt"
end="end.txt"
T=$(date +%Y%m%d%H)
if [ ! -d history ];then
    mkdir history
fi
ps -ef|egrep -v 'TaskTracker|DataNode'|grep ^work|awk '{print $5,$2}' > $job
egrep -v '^[0-9][0-9]' $job|awk '{print $2}' > $end
if [ -s $end ];then
    while read p;do
        ps -ef|egrep -v 'TaskTracker|DataNode'|grep ^work|awk -v  var=$p '$2~/var/ {print $0}' >> ./history/$T.log
        kill -9 $p
    done<$end
fi