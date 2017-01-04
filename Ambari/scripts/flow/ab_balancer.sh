#!/bin/sh
SCRIPT_FLOW_DIR=${SCRIPT_FLOW_DIR:-`pwd`}
SCRIPTS_DIR=${SCRIPTS_DIR:-$SCRIPT_FLOW_DIR/..}
. ../../conf/conf

check=$(ps aux | 'grep org.apache.hadoop.hdfs.server.balancer.Balancer$')
if [ -z "$check" ]
then
  /usr/bin/kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs
  hdfs balancer
fi
