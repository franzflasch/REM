#!/bin/bash

BASEDIR=$(dirname "$0")
REM_PATH=$1

BUILD_ITEM_NAME=()
BUILD_ITEM_RESULT=()

for f in $BASEDIR/tests/TEST_*.sh ; 
do
	$f $REM_PATH
	BUILD_ITEM_RESULT+=("$?")
	BUILD_ITEM_NAME+=("$f")
done

for ((i=0; i < ${#BUILD_ITEM_RESULT[@]}; i++))
do
	if [[ ${BUILD_ITEM_RESULT[$i]} != 0 ]]; then
		echo "${BUILD_ITEM_NAME[$i]} not passed!"
		exit 1
	else
		echo "${BUILD_ITEM_NAME[$i]} passed!"
	fi
done

exit 0
