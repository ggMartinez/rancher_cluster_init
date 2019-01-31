#!/bin/bash

#######################################################
###
### 01-30-2019
###
### Created by Gonzalo Martinez
### Based on the Gist from Sebastiaan van Steenis (superseb)
###    https://gist.github.com/superseb/
###    https://gist.githubusercontent.com/superseb/c363247c879e96c982495daea1125276/raw/98d9c0590992f2b7e209ae4e0a7da7da1db5aee0/rancher2customnodecmd.sh
###
#######################################################

# Get parametres
# -----------------------
SERVER_NAME=$1
CLUSTER_NAME=$2
ADMIN_PASSWORD=$3


# Check if server is alive
# -----------------------
STATUS=`curl 'https://localhost/ping' 2>/dev/null --insecure`
if [ "$STATUS" != "pong" ]
then
      echo "Rancher is not running. Aborting..."
      exit 1
fi

# Get auth token
# -----------------------

# Login
LOGINRESPONSE=`curl -s 'https://127.0.0.1/v3-public/localProviders/local?action=login' -H 'content-type: application/json' --data-binary '{"username":"admin","password":"admin"}' --insecure`
LOGINTOKEN=`echo $LOGINRESPONSE | jq -r .token`

# Change admin Password
# ----------------------
curl -s 'https://127.0.0.1/v3/users?action=changepassword' -H 'content-type: application/json' -H "Authorization: Bearer $LOGINTOKEN" --data-binary "{\"currentPassword\":\"admin\",\"newPassword\":\"$ADMIN_PASSWORD\"}" --insecure

# Create API key
# ----------------------
APIRESPONSE=`curl -s 'https://127.0.0.1/v3/token' -H 'content-type: application/json' -H "Authorization: Bearer $LOGINTOKEN" --data-binary '{"type":"token","description":"automation"}' --insecure`

# Extract and store token
# ----------------------
APITOKEN=`echo $APIRESPONSE | jq -r .token`

# Configure server-url
# ----------------------
RANCHER_SERVER="https://$SERVER_NAME"
curl -s 'https://127.0.0.1/v3/settings/server-url' -H 'content-type: application/json' -H "Authorization: Bearer $APITOKEN" -X PUT --data-binary "{\"name\":\"server-url\",\"value\":\"$SERVER_NAME\"}" --insecure

# Create cluster
# ----------------------
CLUSTERRESPONSE=`curl -s 'https://127.0.0.1/v3/cluster' -H 'content-type: application/json' -H "Authorization: Bearer $APITOKEN" --data-binary "{\"type\":\"cluster\",\"nodes\":[],\"rancherKubernetesEngineConfig\":{\"ignoreDockerVersion\":true},\"name\":\"$CLUSTER_NAME\"}" --insecure`

# Extract clusterid to use for generating the docker run command
# ----------------------
CLUSTERID=`echo $CLUSTERRESPONSE | jq -r .id`

# Get nodeCommand to add Master nodes
# -------------------------------------

# TODO: Try to quit the sed, and get the right server name

# Specify role flags to use
ROLEFLAGS="--etcd --controlplane --worker"

# Generate token (clusterRegistrationToken) and extract nodeCommand
AGENTCOMMAND=`curl -s 'https://127.0.0.1/v3/clusterregistrationtoken' -H 'content-type: application/json' -H "Authorization: Bearer $APITOKEN" --data-binary '{"type":"clusterRegistrationToken","clusterId":"'$CLUSTERID'"}' --insecure | jq -r .nodeCommand`

# Show the command
echo "To add Master nodes run '${AGENTCOMMAND} ${ROLEFLAGS}'" sed  "s|--server|--server $RANCHER_SERVER|g"



# Get nodeCommand to add Worker nodes
# -------------------------------------

# Specify role flags to use
ROLEFLAGS="--worker"

# Generate token (clusterRegistrationToken) and extract nodeCommand
AGENTCOMMAND=`curl -s 'https://127.0.0.1/v3/clusterregistrationtoken' -H 'content-type: application/json' -H "Authorization: Bearer $APITOKEN" --data-binary '{"type":"clusterRegistrationToken","clusterId":"'$CLUSTERID'"}' --insecure | jq -r .nodeCommand`

# Show the command
echo "To add Worker nodes run '${AGENTCOMMAND} ${ROLEFLAGS}'" | sed  "s|--server|--server $RANCHER_SERVER|g"


# Finish Message
# ---------------
echo "Process completed."
