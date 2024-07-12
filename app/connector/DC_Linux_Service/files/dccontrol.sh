#!/bin/sh
BASEDIR=$(dirname "$0")
FILE_NAME=dccontrol
CURRENTDIR=$(pwd)
cd $BASEDIR
sudo java -jar $FILE_NAME.jar
cd $CURRENTDIR