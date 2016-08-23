#!/bin/sh
SCRIPT_DIR=${SCRIPT_DIR:-`pwd`}
. ../conf/conf

# public key
HBASE_COM_KEY_FILE="$COM_KEY_OUTPUT_DIR/hbase.headless.keytab"
if [ ! -f "$HBASE_COM_KEY_FILE" ]
then
  kadmin.local -q "addprinc -randkey hbase$DEFAULT_REALM"
  kadmin.local -q "xst -k $HBASE_COM_KEY_FILE hbase$DEFAULT_REALM"
  chown hbase:hadoop $HBASE_COM_KEY_FILE
  chmod 440 $HBASE_COM_KEY_FILE
fi

HDFS_COM_KEY_FILE="$COM_KEY_OUTPUT_DIR/hdfs.headless.keytab"
if [ ! -f "$HDFS_COM_KEY_FILE" ]
then
  kadmin.local -q "addprinc -randkey hdfs$DEFAULT_REALM"
  kadmin.local -q "xst -k $HDFS_COM_KEY_FILE hdfs$DEFAULT_REALM"
  chown hdfs:hadoop $HDFS_COM_KEY_FILE
  chmod 440 $HDFS_COM_KEY_FILE
fi

SMOKEUSER_COM_KEY_FILE="$COM_KEY_OUTPUT_DIR/smokeuser.headless.keytab"
if [ ! -f "$SMOKEUSER_COM_KEY_FILE" ]
then
  kadmin.local -q "addprinc -randkey ambari-qa$DEFAULT_REALM"
  kadmin.local -q "xst -k $SMOKEUSER_COM_KEY_FILE ambari-qa$DEFAULT_REALM"
  chown ambari-qa:hadoop $SMOKEUSER_COM_KEY_FILE
  chmod 440 $SMOKEUSER_COM_KEY_FILE
fi

AMBARI_COM_KEY_FILE="$COM_KEY_OUTPUT_DIR/ambari.keytab"
if [ ! -f "$AMBARI_COM_KEY_FILE" ]
then
  kadmin.local -q "addprinc -randkey ambari$DEFAULT_REALM"
  kadmin.local -q "xst -k $AMBARI_COM_KEY_FILE ambari$DEFAULT_REALM"
  chown work:hadoop $AMBARI_COM_KEY_FILE
  chmod 400 $AMBARI_COM_KEY_FILE
fi

create_key()
{
  HOST=$1
  HOST_KEY_OUTPUT_DIR="$KEY_OUTPUT_DIR/$HOST"
  mkdir -p $HOST_KEY_OUTPUT_DIR
  rm -f $HOST_KEY_OUTPUT_DIR/*.keytab

  kadmin.local -q "addprinc -randkey nn/$HOST$DEFAULT_REALM"
  kadmin.local -q "addprinc -randkey HTTP/$HOST$DEFAULT_REALM"
  kadmin.local -q "addprinc -randkey dn/$HOST$DEFAULT_REALM"
  kadmin.local -q "addprinc -randkey jhs/$HOST$DEFAULT_REALM"
  kadmin.local -q "addprinc -randkey rm/$HOST$DEFAULT_REALM"
  kadmin.local -q "addprinc -randkey nm/$HOST$DEFAULT_REALM"
  kadmin.local -q "addprinc -randkey oozie/$HOST$DEFAULT_REALM"
  kadmin.local -q "addprinc -randkey hive/$HOST$DEFAULT_REALM"
  kadmin.local -q "addprinc -randkey hbase/$HOST$DEFAULT_REALM"
  kadmin.local -q "addprinc -randkey zookeeper/$HOST$DEFAULT_REALM"
  kadmin.local -q "addprinc -randkey nagios/$HOST$DEFAULT_REALM"
  kadmin.local -q "addprinc -randkey jn/$HOST$DEFAULT_REALM"
  kadmin.local -q "addprinc -randkey falcon/$HOST$DEFAULT_REALM"
  kadmin.local -q "addprinc -randkey storm/$HOST$DEFAULT_REALM"

  kadmin.local -q "xst -k $HOST_KEY_OUTPUT_DIR/nn.service.keytab nn/$HOST$DEFAULT_REALM"
  kadmin.local -q "xst -k $HOST_KEY_OUTPUT_DIR/spnego.service.keytab HTTP/$HOST$DEFAULT_REALM"
  kadmin.local -q "xst -k $HOST_KEY_OUTPUT_DIR/dn.service.keytab dn/$HOST$DEFAULT_REALM"
  kadmin.local -q "xst -k $HOST_KEY_OUTPUT_DIR/jhs.service.keytab jhs/$HOST$DEFAULT_REALM"
  kadmin.local -q "xst -k $HOST_KEY_OUTPUT_DIR/rm.service.keytab rm/$HOST$DEFAULT_REALM"
  kadmin.local -q "xst -k $HOST_KEY_OUTPUT_DIR/nm.service.keytab nm/$HOST$DEFAULT_REALM"
  kadmin.local -q "xst -k $HOST_KEY_OUTPUT_DIR/oozie.service.keytab oozie/$HOST$DEFAULT_REALM"
  kadmin.local -q "xst -k $HOST_KEY_OUTPUT_DIR/hive.service.keytab hive/$HOST$DEFAULT_REALM"
  kadmin.local -q "xst -k $HOST_KEY_OUTPUT_DIR/hbase.service.keytab hbase/$HOST$DEFAULT_REALM"
  kadmin.local -q "xst -k $HOST_KEY_OUTPUT_DIR/zk.service.keytab zookeeper/$HOST$DEFAULT_REALM"
  kadmin.local -q "xst -k $HOST_KEY_OUTPUT_DIR/nagios.service.keytab nagios/$HOST$DEFAULT_REALM"
  kadmin.local -q "xst -k $HOST_KEY_OUTPUT_DIR/jn.service.keytab jn/$HOST$DEFAULT_REALM"
  kadmin.local -q "xst -k $HOST_KEY_OUTPUT_DIR/falcon.service.keytab falcon/$HOST$DEFAULT_REALM"
  kadmin.local -q "xst -k $HOST_KEY_OUTPUT_DIR/storm.service.keytab storm/$HOST$DEFAULT_REALM"

  chown falcon:hadoop $HOST_KEY_OUTPUT_DIR/falcon.service.keytab
  chmod 440 $HOST_KEY_OUTPUT_DIR/falcon.service.keytab

  chown hdfs:hadoop $HOST_KEY_OUTPUT_DIR/nn.service.keytab 
  chmod 400 $HOST_KEY_OUTPUT_DIR/nn.service.keytab
  chown root:hadoop $HOST_KEY_OUTPUT_DIR/spnego.service.keytab 
  chmod 440 $HOST_KEY_OUTPUT_DIR/spnego.service.keytab

  chown hdfs:hadoop $HOST_KEY_OUTPUT_DIR/dn.service.keytab 
  chmod 400 $HOST_KEY_OUTPUT_DIR/dn.service.keytab

  chown mapred:hadoop $HOST_KEY_OUTPUT_DIR/jhs.service.keytab 
  chmod 400 $HOST_KEY_OUTPUT_DIR/jhs.service.keytab 
  chown root:hadoop $HOST_KEY_OUTPUT_DIR/spnego.service.keytab 
  chmod 440 $HOST_KEY_OUTPUT_DIR/spnego.service.keytab

  chown yarn:hadoop $HOST_KEY_OUTPUT_DIR/rm.service.keytab 
  chmod 400 $HOST_KEY_OUTPUT_DIR/rm.service.keytab

  chown yarn:hadoop $HOST_KEY_OUTPUT_DIR/nm.service.keytab 
  chmod 400 $HOST_KEY_OUTPUT_DIR/nm.service.keytab

  chown oozie:hadoop $HOST_KEY_OUTPUT_DIR/oozie.service.keytab 
  chmod 400 $HOST_KEY_OUTPUT_DIR/oozie.service.keytab
  chown root:hadoop $HOST_KEY_OUTPUT_DIR/spnego.service.keytab 
  chmod 440 $HOST_KEY_OUTPUT_DIR/spnego.service.keytab

  chown hive:hadoop $HOST_KEY_OUTPUT_DIR/hive.service.keytab 
  chmod 400 $HOST_KEY_OUTPUT_DIR/hive.service.keytab
  chown root:hadoop $HOST_KEY_OUTPUT_DIR/spnego.service.keytab 
  chmod 440 $HOST_KEY_OUTPUT_DIR/spnego.service.keytab

  chown hbase:hadoop $HOST_KEY_OUTPUT_DIR/hbase.service.keytab 
  chmod 400 $HOST_KEY_OUTPUT_DIR/hbase.service.keytab
  chown zookeeper:hadoop $HOST_KEY_OUTPUT_DIR/zk.service.keytab 
  chmod 400 $HOST_KEY_OUTPUT_DIR/zk.service.keytab

  chown nagios:nagios $HOST_KEY_OUTPUT_DIR/nagios.service.keytab
  chmod 400 $HOST_KEY_OUTPUT_DIR/nagios.service.keytab

  chown hdfs:hadoop $HOST_KEY_OUTPUT_DIR/jn.service.keytab
  chmod 400 $HOST_KEY_OUTPUT_DIR/jn.service.keytab

  cp -a $HBASE_COM_KEY_FILE $HDFS_COM_KEY_FILE $SMOKEUSER_COM_KEY_FILE $AMBARI_COM_KEY_FILE $HOST_KEY_OUTPUT_DIR
}

for i in $(grep -v '#' $NEW_LIST_INPUT | awk '{print $2}' )
do
  create_key $i
done
