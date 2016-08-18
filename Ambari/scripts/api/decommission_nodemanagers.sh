#!/bin/sh
. ../../conf/conf

EXCLUDED_HOSTS_INPUT_CONTENT="$(grep -v '#' $EXCLUDED_HOSTS_INPUT | awk '{print $2}' | xargs | sed 's/ /,/g')"
curl -u $AMBARI_USER:$AMBARI_PASSWD -i -H 'X-Requested-By: ambari' -X POST -d '{
   "RequestInfo":{
      "context":"Decommission NodeManagers",
      "command":"DECOMMISSION",
      "parameters":{
         "slave_type":"NODEMANAGER",
         "excluded_hosts":"'$EXCLUDED_HOSTS_INPUT_CONTENT'"
      },
      "operation_level":{
         "level":"HOST_COMPONENT",
         "cluster_name":"'$AMBARI_CLUSTER'"
      }
   },
   "Requests/resource_filters":[
      {
         "service_name":"YARN",
         "component_name":"RESOURCEMANAGER"
      }
   ]
}' $AMBARI_REQUESTS
