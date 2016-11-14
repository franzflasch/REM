#!/bin/bash

BASEDIR=$(dirname "$0")

BUILD_ITEM_NAME=()
BUILD_ITEM_RESULT=()

for f in $BASEDIR/docker/*.dockertest ; 
do
	docker build -f "$f" .
	BUILD_ITEM_RESULT+=("$?")
	BUILD_ITEM_NAME+=("$f")
	docker rmi --force $(sudo docker images --filter "dangling=true" -q --no-trunc)
done

for ((i=0; i < ${#BUILD_ITEM_RESULT[@]}; i++))
do
	if [[ ${BUILD_ITEM_RESULT[$i]} != 0 ]]; then
		echo "${BUILD_ITEM_NAME[$i]} not passed!"
	else
		echo "${BUILD_ITEM_NAME[$i]} passed!"
		exit 1
	fi
done
