#!/bin/bash
export KEY_NAME_BUILD=keypairIII
export PEM_BUILD=/home/n/keypairIII.pem
#export SECURITY_GROUP_IDS_BUILD=sg-78125f1d
#logical name is necessary as well as id because for some reason
#cloudFormation specifically requires the logical name as well.
export SECURITY_GROUP_NAME_BUILD=default
export BUCKET_NAME_BUILD=testbucket303902
export SUBNET_ID_BUILD=5a24803f
export REGION_BUILD=us-west-2



export KEY_NAME_RUN=keypairIII
export PEM_RUN=/home/n/keypairIII.pem
#export SECURITY_GROUP_IDS_RUN=sg-78125f1d
export SECURITY_GROUP_NAME_RUN=default
export BUCKET_NAME_RUN=testbucket303902
export SUBNET_ID_RUN=5a24803f
export REGION_RUN=us-west-2

#set to 1 to make it a little quieter.
export VERBOSE=3

args=( $@ )
eval $1 ${args[@]:1}

