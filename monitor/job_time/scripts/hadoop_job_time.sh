#!/bin/bash
#20140825 Written by Yann (yannan@sogou-inc.com)

set -u
HADOOP="/search/work/hadoop-envir/hadoop-jobtracker/bin/hadoop"
HOUR_START=22
HOUR_END=10
DATE_61MIN_AGO=$(date -d "123 minutes ago" +"%Y%m%d")
NOW_SECOND=$(date +"%s")
NOW_MIN=$(date +"%M")
NOW_HOUR=$(date +"%H")
NOW_DATE=$(date +"%Y%m%d")
NOW_YEAR=$(date +"%Y")
NOW_MONTH=$(date +"%m")
NOW_DAY=$(date +"%d")
NOW_YMD=$NOW_YEAR/$NOW_MONTH/$NOW_DAY

NOW_YEAR_DEL=$(date -d'30 days ago' +"%Y")
NOW_MONTH_DEL=$(date -d'30 days ago' +"%m")
NOW_DAY_DEL=$(date -d'30 days ago' +"%d")
NOW_YMD_DEL=$NOW_YEAR_DEL/$NOW_MONTH_DEL/$NOW_DAY_DEL

LOG="/search/work/hadoop-envir/hadoop-jobtracker/logs/history"
SMSHEAD="Common/hadoop/white_kill"
HOST="maserati"
WHITE_JOBNAME="white_jobname.list"
WHITE_JOBUSER="white_jobuser.list"
BLACK_JOBNAME="black_jobname.list"
WHITE_JOBNAME_MAPNUM="white_jobname_mapnum.list"

JOB_LIST="job_list"
KILL_LIST="job_to_kill"
TIME=$(date +"%H%M%S")
R_NUM=$RANDOM
JOB_LIST="logs/$NOW_YMD/$JOB_LIST.${NOW_DATE}_${TIME}.$R_NUM"
KILL_LIST="logs/$NOW_YMD/$KILL_LIST.${NOW_DATE}_${TIME}.$R_NUM"

mkdir -p logs/$NOW_YMD

if [[ $NOW_HOUR == "00" && $NOW_MIN == "00" ]]
then
  > $BLACK_JOBNAME
  echo 'Adrptask3_ADW_QIPENG' >> $BLACK_JOBNAME
fi

LOG_DIR="$LOG/$DATE_61MIN_AGO"
if [ -n "$(grep -E '^distcp$' $BLACK_JOBNAME)" ]
then
    sed -ri '/^distcp$/d' $BLACK_JOBNAME
fi
#for i in $WHITE_JOBNAME $WHITE_JOBUSER $BLACK_JOBNAME
#do
#    if [ ! -f "$i" ]
#    then
#        touch $i
#    fi
#done

cd $LOG_DIR
FILELIST=$(find . -mmin -123 | sed -r 's/^.$|^..//g' | grep -Ev '^\..*\.crc$')
cd - > /dev/null

FILELIST_XML=$(echo "$FILELIST" | grep -E  '\.xml$')
FILELIST_LOG=$(echo "$FILELIST" | grep -Ev '\.xml$')

> $JOB_LIST
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
    }' $LOG_DIR/$FILE | sed 's/\\//g' >> $JOB_LIST
done

# 绝对白名单
sed -i '/sky_system_update_job/d' $JOB_LIST
#sed -ri 's/^[[:blank:]]+|[[:blank:]]+$//g' $WHITE_JOBNAME $WHITE_JOBUSER

awk -F'\t' '{
    if(FILENAME=="'$WHITE_JOBNAME'")
    {
        job_name[$0]=1
    }
    if(FILENAME=="'$WHITE_JOBUSER'")
    {
        job_user[$0]=1
    }
    if(FILENAME=="'$BLACK_JOBNAME'")
    {
        job_black[$0]=1
    }
    if(FILENAME=="'$WHITE_JOBNAME_MAPNUM'")
    {
        job_name_mapnum[$0]=1
    }
    if(FILENAME=="'$JOB_LIST'")
    {
        if(job_name_mapnum[$9]==0 && $10 > 30000)
        {
            print $0
            system("\"'$HADOOP'\" job -kill "$5)
            system("sh /opt/mail/sendmail.sh -t yannan@sogou-inc.com -c \"[\"'$SMSHEAD'\"][hadoop_monitor:\"'$HOST'\" kill BIGMAP job "$9"]\" > /dev/null")
        }
        if($7 > 7200 || job_black[$9]==1)
        {
            print $0
            system("\"'$HADOOP'\" job -kill "$5)
            system("sh /opt/mail/sendmail.sh -t yannan@sogou-inc.com -c \"[\"'$SMSHEAD'\"][hadoop_monitor:\"'$HOST'\" kill too long job "$9"]\" > /dev/null")
            if(job_black[$9]!=1)
            {
                print $9 >> "'$BLACK_JOBNAME'"
            }
        }
        else
        {
            if( '$HOUR_START' <= '$NOW_HOUR' || '$NOW_HOUR' < '$HOUR_END')
            {
                if(job_user[$8]==0 && job_name[$9]==0)
                {
                    print $0
                    system("\"'$HADOOP'\" job -kill "$5)
                }
            }
        }
    }
}' $WHITE_JOBNAME_MAPNUM $WHITE_JOBNAME $WHITE_JOBUSER $BLACK_JOBNAME $JOB_LIST >> $KILL_LIST
                    #system("sh /opt/mail/sendmail.sh -t yannan@sogou-inc.com -c \"[\"'$SMSHEAD'\"][hadoop_monitor:\"'$HOST'\" job ::"$NF":: is not in white_list,killed]\" > /dev/null")
if [ $(ls -l $KILL_LIST | awk '{print $5}') -eq 0 ]
then
    rm -f $KILL_LIST
    rm -f $JOB_LIST
fi
rm -rf logs/$NOW_YMD_DEL

rm -f temp_wget_mail
sh hadoop_job_time.sh >> hadoop_job_time.log 2>&1 &
