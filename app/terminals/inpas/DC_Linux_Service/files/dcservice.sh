#!/bin/sh
SERVICE_NAME=DC_Service
SERVICE_NAME=dualconnector
SIMPLY_NAME=dcservice
PATH_TO_JAR=/usr/local/service/$SIMPLY_NAME/$SIMPLY_NAME.jar
### BEGIN INIT INFO
# Provides:          dualconnector
# Required-Start:    $all
# Required-Stop:     
# Should-Start:      
# Should-Stop:       
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Dual Connector Service for Linux
### END INIT INFO
echo "args($#): $@"
if [ -z $2 ]; then
PID_PATH_NAME=/var/run/$SIMPLY_NAME.pid
else
PID_PATH_NAME=$2
fi
echo "pid path $PID_PATH_NAME"
if [ -z $3 ]; then
LOG_PATH_NAME=/tmp/$SIMPLY_NAME
else
LOG_PATH_NAME=$3
fi
echo "log path $LOG_PATH_NAME"

start(){
	echo "Starting $SERVICE_NAME ..."
	if [ ! -f $PID_PATH_NAME ]; then
		if [ ! -d $LOG_PATH_NAME ]; then
			mkdir -p $LOG_PATH_NAME 
		fi
		nohup java -jar $PATH_TO_JAR 2>> $LOG_PATH_NAME/stderr >> $LOG_PATH_NAME/stdout &
		echo $! > $PID_PATH_NAME
		echo $!
		echo "$SERVICE_NAME started ..."
	else
		echo "$SERVICE_NAME is already running ..."
	fi
}

stop() {
	if [ -f $PID_PATH_NAME ]; then
		PID=$(cat $PID_PATH_NAME);
		echo "$SERVICE_NAME stoping ..."
		kill $PID;
		sleep 5
		echo "$SERVICE_NAME stopped ..."
		rm $PID_PATH_NAME
	else
		echo "$SERVICE_NAME is not running ..."
	fi
}

restart() {
	if [ -f $PID_PATH_NAME ]; then
		PID=$(cat $PID_PATH_NAME);
		echo "$SERVICE_NAME stopping ...";
		kill $PID;
		sleep 5
		echo "$SERVICE_NAME stopped ...";
		rm $PID_PATH_NAME
		echo "$SERVICE_NAME starting ..."
		nohup java -jar $PATH_TO_JAR 2>> $LOG_PATH_NAME/stderr >> $LOG_PATH_NAME/stdout &
		echo $! > $PID_PATH_NAME
		echo "$SERVICE_NAME started ..."
	else
		echo "$SERVICE_NAME is not running ..."
	fi
}

case $1 in
	start)
		start
	;;
	stop)
		stop
	;;
	restart)
		restart
	;;
	*)
		echo "Usage: {start|stop|restart}"
	;;
esac 
