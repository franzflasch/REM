#!/bin/bash

BASEDIR=$(dirname "$0")

docker build -f $BASEDIR/docker/dockerfile_"$1"_"$2".dockertest .
