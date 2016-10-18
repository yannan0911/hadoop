#!/bin/bash
#var
CHECK_EXCLUDE="(grep |vi |vim |tail |cat |head |more |less |emacs |cd )"
hadoop_datanode="/search/work/hadoop-envir/hadoop-datanode/bin"
hadoop_tasktracker="/search/work/hadoop-envir/hadoop-tasktracker/bin"
hadoop_namenode="/search/work/hadoop-envir/hadoop-namenode/bin/"
hadoop_jobtracker="/search/work/hadoop-envir/hadoop-jobtracker/bin/"
#res="39845888"
res="10485760"
#24*100*60%
cuse="1440"
nowtime=`date "+%Y%m%d%H%M%S"`
progress_tmp="./progress_tmp.$nowtime"
progress_list_tmp="./progress_list_tmp.$nowtime"
#action
ps aux > $progress_tmp
ps -ef f > ${progress_list_tmp}
#mem
mem=`cat $progress_tmp| grep ^"work" | grep -v "$hadoop_jobtracker" | grep -v "$hadoop_namenode" | grep -v "$hadoop_datanode" | grep -v "$hadoop_tasktracker" | grep -Ev "$CHECK_EXCLUDE|RSS" | awk '{print $6}'`
cpu=`cat $progress_tmp| grep ^"work" | grep -v "$hadoop_jobtracker" | grep -v "$hadoop_namenode" | grep -v "$hadoop_datanode" | grep -v "$hadoop_tasktracker" | grep -Ev "$CHECK_EXCLUDE|RSS" | awk '{print $3}'|awk -F"." '{print $1}'`
for num in $mem;do
    if [ "${num}" -gt "${res}" ];then
        PID=$(awk -v var=$num '$6==var {print $2}' $progress_tmp)
        echo $PID >> ./history/pid_list_$nowtime
    fi
done
for cnum in $cpu;do
    if [ "${cnum}" -gt "${cuse}" ];then
        echo "${cpu}" >> ./history/cpu_$nowtime.txt
    fi
done
if [[ -s ./history/pid_list_$nowtime ]];then 
    for p in $(cat ./history/pid_list_$nowtime);do
        echo $p |xargs kill -9
    done
fi
#check mv
if [ -s ./history/pid_list_$nowtime -o  -s ./history/cpu_$nowtime.txt ];then
    mv  $progress_tmp  "./history/progress_list_$nowtime"
    mv ${progress_list_tmp} "./history/progress_tree_list__$nowtime"   
else
        rm -f $progress_tmp
        rm -f ${progress_list_tmp}
fi