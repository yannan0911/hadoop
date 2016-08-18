#!/bin/sh
SCRIPT_DIR=${SCRIPT_DIR:-`pwd`}
. ../conf/conf
SERVER_IP=$(ip a | sed -rn '/scope global eth0/s/.*inet[[:blank:]]([0-9.]+)\/.*/\1/gp')

# 仅当 key 不存在时创建新 key
if [ ! -f $PRI_KEY_FILE ]
then
  /usr/bin/ssh-keygen -t rsa -f $PRI_KEY_FILE -P ''
fi

# 避免 rsync 对 /root 目录的读权限限制
cp $PUB_KEY_FILE $TMP_DIR

# 新节点列表文件检查
if [ ! -f $HOSTS_INPUT ]
then
  echo "IP LIST: $HOSTS_INPUT No such file."
  exit
fi

# 新节点: 1.建立信任关系; 2.更新 /etc/hosts 文件; 3.更改主机名;
COMMAND="rsync -a $SERVER_IP::root$TMP_DIR/$PUB_KEY_FILENAME /tmp/$PUB_KEY_FILENAME.$SERVER_IP;
         cp /root/.ssh/authorized_keys{,.$SEC1970};
         sort /tmp/$PUB_KEY_FILENAME.$SERVER_IP /root/.ssh/authorized_keys.$SEC1970 | uniq > /root/.ssh/authorized_keys;
         rm -f /tmp/$PUB_KEY_FILENAME.$SERVER_IP;

         mv /etc/hosts{,.$SEC1970};
         rsync -a $SERVER_IP::root$HOSTS_INPUT /etc/hosts;

         HOST_IP=\$(ip a | sed -rn '/scope global eth0/s/.*inet[[:blank:]]([0-9.]+)\/.*/\1/gp');
         HOST_NAME=\$(awk '/'\$HOST_IP'/{print \$2}' /etc/hosts);
         sed -i '/HOSTNAME/s/.*/HOSTNAME='\$HOST_NAME'/g' /etc/sysconfig/network;
         hostname \$HOST_NAME;"
. $SSH_SH "$COMMAND" $NEW_LIST_INPUT

# 所有节点: 更新 /etc/hosts 文件;
COMMAND="mv /etc/hosts{,.$SEC1970};
         rsync -a $SERVER_IP::root$HOSTS_INPUT /etc/hosts;"
. $SSH_SH "$COMMAND" $ALL_LIST_INPUT 