#!/bin/sh
run()
{
    BASEDIR=$(dirname "$0")
    FILE_NAME=dcconsole
    CURRENTDIR=$(pwd)
    cd $BASEDIR
    java -jar $FILE_NAME.jar "$@"
    retval=$?
    cd $CURRENTDIR
    return $retval
}
 
run "$@"
