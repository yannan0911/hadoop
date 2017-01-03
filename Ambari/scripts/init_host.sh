#!/bin/sh
SCRIPTS_DIR=${SCRIPTS_DIR:-`pwd`}
. ../conf/conf
SERVER_IP=$(ip a | sed -rn '/scope global eth0/s/.*inet[[:blank:]]([0-9.]+)\/.*/\1/gp' | head -n 1)

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

# 制作 kerberos keytabs
. $MK_KEYS_SH
 
# 新节点: 1.建立信任关系; 2.更新 /etc/hosts 文件; 3.更改主机名;
#        4.添加 Hadoop 用户,拷贝 kerberos 配置文件及 keytabs;
#        5.拷贝 jdk;
#        SOGO 定制:
#        6.磁盘软链制作; 7.添加各组身份用户,如 adrs.
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

         groupadd hadoop;
         useradd work;
         useradd ambari-qa -g hadoop;
         useradd falcon -g hadoop;
         useradd hbase -g hadoop;
         useradd hdfs -g hadoop;
         useradd hive -g hadoop;
         useradd mapred -g hadoop;
         useradd nagios -g hadoop;
         useradd oozie -g hadoop;
         useradd yarn -g hadoop;
         useradd zookeeper -g hadoop;
         rsync -a $SERVER_IP::root/etc/krb5.conf /etc/krb5.conf;

         rsync -a $SERVER_IP::root/$JDK_DIR/* /$JDK_DIR/;

         mkdir -p /search/ted/hadoop-envir/{var,yarn};
         mkdir -p /search/work/hadoop-envir/etc/hadoop/conf/;
         ln -s /search/ted/hadoop-envir/var /search/work/hadoop-envir/var;
         ln -s /search/ted/hadoop-envir/yarn /search/work/hadoop-envir/yarn;

         rsync -a $SERVER_IP::root/$USERADD_INPUT /tmp/$USERADD_FILENAME.$SERVER_IP;
         for user in \$(grep -v '#' /tmp/$USERADD_FILENAME.$SERVER_IP);do useradd \$user;done;
         rm -f /tmp/$USERADD_FILENAME.$SERVER_IP;
         cp -a /etc/passwd{,.$SEC1970};
         cp -a /etc/group{,.$SEC1970};
         rsync -a $SERVER_IP::root/etc/passwd /etc/passwd;
         rsync -a $SERVER_IP::root/etc/group /etc/group;
         mkdir -p /etc/security/keytabs;
         rsync -a $SERVER_IP::root/$KEY_OUTPUT_DIR/\$HOST_NAME/*.keytab /etc/security/keytabs/"
. $SSH_SH "$COMMAND" $NEW_LIST_INPUT

# 所有节点: 更新 /etc/hosts 文件;
COMMAND="cp -a /etc/hosts{,.$SEC1970};
         rsync -a $SERVER_IP::root$HOSTS_INPUT /etc/hosts;"
. $SSH_SH "$COMMAND" $ALL_LIST_INPUT 
