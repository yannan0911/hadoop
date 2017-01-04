#!/bin/bash
# 20140825 Written by Yann (yannan@sogou-inc.com)
# 黑名单说明：黑名单仅指超时黑名单
#         1.一级黑名单：永不清理
#         2.二级黑名单：每日零点清理
#         3.三级黑名单：特殊任务如：distcp， 进入即清理
SCRIPT_JOB_TIME_DIR=${SCRIPT_JOB_TIME_DIR:-`pwd`}
SCRIPTS_DIR=${SCRIPTS_DIR:-$SCRIPT_JOB_TIME_DIR/../..}
. ../../../conf/conf

set -u

mkdir -p $SCRIPT_JOB_TIME_DIR/logs/$NOW_YMD_DIR
for i in $WHITE_JOBNAME_MAPNUM_LIST $WHITE_JOBNAME_LIST $WHITE_JOBUSER_LIST $BLACK_JOBNAME_LIST
do
   if [ ! -f "$i" ]
   then
       touch $i
   fi
done

# 每日二级黑名单清理
if [[ $NOW_HOUR == "00" && $NOW_MIN == "00" ]]
then
  > $BLACK_JOBNAME_LIST
  # 不清理的一级黑名单
  echo 'Adrptask3_ADW_QIPENG' >> $BLACK_JOBNAME_LIST
fi

# 实时清理三级黑名单
if [ -n "$(grep -E '^distcp$' $BLACK_JOBNAME_LIST)" ]
then
    sed -ri '/^distcp$/d' $BLACK_JOBNAME_LIST
fi

# 获取当前任务信息 (暂时通过任务日志文件判断任务运行情况)
cd $JOB_HISTORY_LOG_DIR
FILELIST=$(find . -mmin -$JOB_TIME_THRESHOLD_OFFSET_MINUTES | sed -r 's/^.$|^..//g' | grep -Ev '^\..*\.crc$')
cd - > /dev/null

FILELIST_XML=$(echo "$FILELIST" | grep -E  '\.xml$')
FILELIST_LOG=$(echo "$FILELIST" | grep -Ev '\.xml$')

> $ALL_JOB_LIST
# 整理任务信息以备后续判断阈值使用
for FILE in $FILELIST_LOG
do
    awk -F'"' 'BEGIN{
        map_start=0
        map_finish=0
        reduce_start=0
        end=0
        map_num=0
    }
    {
        if($5==" TOTAL_MAPS=")
        {
            map_num=$6
        }
        if($4=="MAP" && $5==" START_TIME=" && map_flag==0)
        {
            map_start=substr($6,1,10)
            map_flag=1
        }
        if($4=="MAP"&&$7==" FINISH_TIME=")
        {
            map_finish=substr($8,1,10)
        }
        if($1=="Job JOBID=")
        {
            jobid=$2
        }
        if($3==" JOBNAME=")
        {
            jobname=$4
            jobuser=$6
        }
        if($4=="REDUCE" && $5==" START_TIME=" && reduce_flag==0)
        {
            reduce_start=substr($6,1,10)
            if(length(reduce_start) < 10)
            {
              offset=10-length(reduce_start)
              for(i=offset;i>0;i--) {
                reduce_start=reduce_start*10
              }
            }
            reduce_flag=1
        }
        if($3==" FINISH_TIME=")
        {
            end=substr($4,1,10)
        }
    }
    END{
        if(end==0 && map_start!=0)
        {
            OFS="\t"
            if(reduce_start <= map_finish)
            {
                print "'$NOW_SECOND'",map_start,map_finish,reduce_start,jobid,"'$FILE'","'$NOW_SECOND'"-map_start,jobuser,jobname,map_num
            }
            else
            {
                print "'$NOW_SECOND'",map_start,map_finish,reduce_start,jobid,"'$FILE'","'$NOW_SECOND'"-map_start-(reduce_start-map_finish),jobuser,jobname,map_num
            }
        }
    }' $JOB_HISTORY_LOG_DIR/$FILE | sed 's/\\//g' >> $ALL_JOB_LIST
done

# 绝对白名单：任何情况下都不会被 Kill
sed -i '/sky_system_update_job/d' $ALL_JOB_LIST

# 判断阈值 kill 超值任务记入黑名单
awk -F'\t' '{
    if(FILENAME=="'$WHITE_JOBNAME_LIST'")
    {
        job_name[$0]=1
    }
    if(FILENAME=="'$WHITE_JOBUSER_LIST'")
    {
        job_user[$0]=1
    }
    if(FILENAME=="'$BLACK_JOBNAME_LIST'")
    {
        job_black[$0]=1
    }
    if(FILENAME=="'$WHITE_JOBNAME_MAPNUM_LIST'")
    {
        job_name_mapnum[$0]=1
    }
    if(FILENAME=="'$ALL_JOB_LIST'")
    {
        if(job_name_mapnum[$9]==0 && $10 > '$JOB_TIME_THRESHOLD_MAPNUM')
        {
            print $0
            system("echo \"'$MR'\" job -kill "$5" >> hadoop_jobtime.log")
            system("sh '$MAIL_TOOL' -t '$ADMIN_MAIL' -c \"'$HADOOP_PLATFORM' TTTTTT kill BIGMAP job "$9"\" > /dev/null")
        }
        if($7 > '$JOB_TIME_THRESHOLD_OFFSET_SECOND' || job_black[$9]==1)
        {
            print $0
            system("echo \"'$MR'\" job -kill "$5" >> hadoop_jobtime.log")
            system("sh '$MAIL_TOOL' -t '$ADMIN_MAIL' -c \"'$HADOOP_PLATFORM' TTTTTT kill too long job "$9"\" > /dev/null")
            if(job_black[$9]!=1)
            {
                print $9 >> "'$BLACK_JOBNAME_LIST'"
            }
        }
        else
        {
            if( '$JOB_TIME_HOUR_START' <= '$NOW_HOUR' || '$NOW_HOUR' < '$JOB_TIME_HOUR_END')
            {
                if(job_user[$8]==0 && job_name[$9]==0)
                {
                    print $0
                    system("echo \"'$MR'\" job -kill "$5" >> hadoop_jobtime.log")
                    system("sh '$MAIL_TOOL' -t '$ADMIN_MAIL' -c \"'$HADOOP_PLATFORM' TTTTTT job ::"$9":: is not in white_list,killed\" > /dev/null")
                }
            }
        }
    }
}' $WHITE_JOBNAME_MAPNUM_LIST $WHITE_JOBNAME_LIST $WHITE_JOBUSER_LIST $BLACK_JOBNAME_LIST $ALL_JOB_LIST >> $KILL_JOB_LIST

# 无 kill 的任务则清理 all_job_list 和 kill_job_list
if [ ! -s "$KILL_JOB_LIST" ]
then
    rm -f $KILL_JOB_LIST
    rm -f $ALL_JOB_LIST
fi

# 清理过期日志及临时文件
rm -rf $SCRIPT_JOB_TIME_DIR/logs/$DEL_YMD_DIR
rm -f temp_wget_mail

# 守护进程模式
sh hadoop_jobtime.sh >> hadoop_jobtime.log 2>&1 &
