#!/bin/sh
SCRIPTS_DIR=${SCRIPTS_DIR:-`pwd`}
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
#        4.添加 Hadoop 用户; 5.拷贝 DataNode、TaskTracker Hadoop 目录 及 python 等库文件;
# TODO: 1.此处做成可编辑的配置文件,使用时加载进来
#       2.客户端(HADOOP_NODE_TGZ),分成两个包
#         2.1.hadoop 客户端必要内容(DataNode、TaskTracker、java6、python)
#         2.2.hadoop 客户端管理工具(mem_monitor等)
COMMAND="rsync -a $SERVER_IP::root$TMP_DIR/$PUB_KEY_FILENAME /tmp/$PUB_KEY_FILENAME.$SERVER_IP;
         cp /root/.ssh/authorized_keys{,.$SEC1970};
         chattr -i /root/.ssh/authorized_keys;
         echo '$HADOOP_CENTER_PUBKEY' >> /root/.ssh/authorized_keys;
         sort /tmp/$PUB_KEY_FILENAME.$SERVER_IP /root/.ssh/authorized_keys.$SEC1970 | uniq > /root/.ssh/authorized_keys;
         rm -f /tmp/$PUB_KEY_FILENAME.$SERVER_IP;

         cp -a /etc/hosts{,.$SEC1970};
         rsync -a $SERVER_IP::root$HOSTS_INPUT /etc/hosts;

         HOST_IP=\$(ip a | sed -rn '/scope global eth0/s/.*inet[[:blank:]]([0-9.]+)\/.*/\1/gp');
         HOST_NAME=\$(awk '/'\$HOST_IP'/{print \$2}' /etc/hosts);
         sed -i '/HOSTNAME/s/.*/HOSTNAME='\$HOST_NAME'/g' /etc/sysconfig/network;
         hostname \$HOST_NAME;

         useradd work -d /search/work;

         mkdir -p /search/ted/hadoop/;
         cd /search/ted/hadoop/;
         rsync -a $SERVER_IP::root/$INPUT_DIR/$HADOOP_NODE_TGZ .;
         tar zxf $HADOOP_NODE_TGZ;
         rm -f $HADOOP_NODE_TGZ;
         ln -s /search/ted/hadoop/python /search/python
         ln -s /search/ted/hadoop/work/op /search/work/op
         ln -s /search/ted/hadoop/work/hadoop-envir/java6 /search/work/hadoop-envir/java6;
         ln -s /search/ted/hadoop/work/hadoop-envir/hadoop-datanode /search/work/hadoop-envir/hadoop-datanode;
         ln -s /search/ted/hadoop/work/hadoop-envir/hadoop-tasktracker /search/work/hadoop-envir/hadoop-tasktracker;
         chown -R work:work /search/work;
         chown -R work:work /search/ted/hadoop/work;
         if [ -L /usr/bin/python ];then rm -f /usr/bin/python;else mv /usr/bin/python /usr/bin/python.old.$SEC1970;fi;
         ln -s /search/python/bin/python /usr/bin/python"
. $SSH_SH "$COMMAND" $NEW_LIST_INPUT

# 所有节点: 更新 /etc/hosts 文件;
COMMAND="cp -a /etc/hosts{,.$SEC1970};
         rsync -a $SERVER_IP::root$HOSTS_INPUT /etc/hosts;"
. $SSH_SH "$COMMAND" $ALL_LIST_INPUT 
