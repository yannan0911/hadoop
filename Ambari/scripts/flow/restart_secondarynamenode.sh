#!/bin/sh
SCRIPT_FLOW_DIR=${SCRIPT_FLOW_DIR:-`pwd`}
SCRIPTS_DIR=${SCRIPTS_DIR:-$SCRIPT_FLOW_DIR/..}
. ../../conf/conf

sudo -u work sh $NAMENODE_DIR/bin/stop-secondarynamenode.sh
sleep 120
sudo -u work sh $NAMENODE_DIR/bin/start-secondarynamenode.sh