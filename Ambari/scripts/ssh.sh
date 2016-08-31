#!/bin/sh
SCRIPTS_DIR=${SCRIPTS_DIR:-`pwd`}
if [ "$#" -eq 0 -o "$#" -gt 2 ]
then
  echo 'Invalid parameter number'
  exit
elif [ "$#" -eq 2 -a -f "$2" ]
then
  LIST_INPUT="$2"
fi
. ../conf/conf

# 判断是否有 INPUT 列表问题件
if [ ! -f $LIST_INPUT ]
then
  echo "IP LIST: $LIST_INPUT No such file."
  exit
fi

# 关闭 ssh knownhost 校验
CHECK_CONFIG=$(grep -E 'StrictHostKeyChecking[[:blank:]]no' ~/.ssh/config | wc -l)
if [ $CHECK_CONFIG -eq 0 ]
then
  mkdir -p ~/.ssh
  echo 'StrictHostKeyChecking no' >> ~/.ssh/config
fi

# 初始化必要文件
touch $PSWD_TMP
chmod +x $PSWD_TMP
> $FAILED_LIST_TMP

# 获取服务器列表
LIST_INPUT_CONTENT=$(cat $LIST_INPUT | grep -v '#')
LINE=$(echo "$LIST_INPUT_CONTENT" | wc -l)
if [ -z "$LIST_INPUT_CONTENT" ]
then
  echo "IP LIST: $LIST_INPUT is empty"
  exit
fi

i=1
while [ $i -le $LINE ]
do
  HOSTINFO=$(echo "$LIST_INPUT_CONTENT" | awk 'NR=='$i'{print $0}')
  IP=$(echo $HOSTINFO | awk '{print $1}')
  PASSWORD=$(echo $HOSTINFO | awk '{print $3}')
  ((i++))
  echo -e "$IP"

# 生成密码文件 由于 EOF 问题无法键入前置空格
cat >$PSWD_TMP<<EOF
#!/bin/sh
echo '$PASSWORD'
EOF

  # 执行远程命令
  echo "$1"|setsid env SSH_ASKPASS=$PSWD_TMP DISPLAY='none:0' ssh -T root@$IP -o NumberOfPasswordPrompts=1 -o ConnectTimeout=3 2>&1
  if [ $? -ne 0 ]
  then
    echo $IP >> $FAILED_LIST_TMP
  fi
done
