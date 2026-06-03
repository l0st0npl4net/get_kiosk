#!/bin/bash
BASEDIR=$(dirname "$0")
SERVICE_NAME=dualconnector
SIMPLY_NAME=dcservice
DCCONSOLE=dcconsole
DCCONTROL=dccontrol
DCUPDATER=dcupdater
INSTALL_PATH=/usr/local/service/$SIMPLY_NAME/
INSTALL_PATH_BIN=/usr/local/bin/
CONFIG_FILE=connector.xml
CONFIG_PATH=/etc/
CONFIG_FILE_UP=updater.xml
CONFIG_PATH_UP=/etc/DCUpdater


# get system init
checkInitSystem()
{
	systemd --version 2>/dev/null >/dev/null
	if [ $? -eq 127 ]; then
		init --version 2>/dev/null >/dev/null
		if [ $? -eq 127 ]; then
			initSystem=127
		else 
			initSystem=2
		fi
	else 
		initSystem=1
	fi
}

# get java 
checkJava()
{
	java --version 2>/dev/null >/dev/null
	if [ $? -eq 127 ]; then
		checkinstalljava=127
	else 
		checkinstalljava=0
	fi
}

# install DC Service
install()
{
	if [ ! -d $INSTALL_PATH ]; then
		mkdir -p $INSTALL_PATH 
	fi
	pushd $BASEDIR/files/ > /dev/null
	# copy java library
	cp $SIMPLY_NAME.jar $INSTALL_PATH
	chmod +rx $INSTALL_PATH$SIMPLY_NAME.jar
	# copy config file
	cp $CONFIG_FILE $CONFIG_PATH
	if [ ! -d $CONFIG_PATH_UP ]; then
		mkdir -p $CONFIG_PATH_UP 
	fi
	if [ ! -f "$CONFIG_PATH_UP/$CONFIG_FILE_UP" ]; then
		cp $CONFIG_FILE_UP $CONFIG_PATH_UP
	fi
	# copy binary files
	cp $DCCONSOLE.jar $INSTALL_PATH_BIN
	cp $DCCONSOLE.sh $INSTALL_PATH_BIN$DCCONSOLE
	chmod +rx $INSTALL_PATH_BIN$DCCONSOLE.jar
	chmod +rx $INSTALL_PATH_BIN$DCCONSOLE
	cp $DCCONTROL.jar $INSTALL_PATH_BIN
	cp $DCCONTROL.sh $INSTALL_PATH_BIN$DCCONTROL
	chmod +rx $INSTALL_PATH_BIN$DCCONTROL.jar
	chmod +rx $INSTALL_PATH_BIN$DCCONTROL
	cp $DCUPDATER.jar $INSTALL_PATH_BIN
	cp $DCUPDATER.sh $INSTALL_PATH_BIN$DCUPDATER
	chmod +rx $INSTALL_PATH_BIN$DCUPDATER.jar
	chmod +rx $INSTALL_PATH_BIN$DCUPDATER
	if [ $? -eq 0 ]; then
		case $initSystem in
			1)
			cp $SERVICE_NAME.service /etc/systemd/system/
			cp $SIMPLY_NAME.sh /usr/local/bin/
			chmod +x /usr/local/bin/$SIMPLY_NAME.sh
			systemctl daemon-reload
			systemctl enable $SERVICE_NAME
			systemctl start $SERVICE_NAME
			;;
			2)
			# copy and rename shell script file
			cp $SIMPLY_NAME.sh /etc/init.d/$SERVICE_NAME
			chmod +x /etc/init.d/$SERVICE_NAME
			update-rc.d $SERVICE_NAME defaults 2>/dev/null
			if [ $? -eq 127 ]; then
				chkconfig --add dualconnector
			fi
			service $SERVICE_NAME start
			;;
		esac
	else
		echo "Ошибка копирования"
	fi
	popd > /dev/null
}

# uninstall DC Service
uninstall()
{
	echo uninstall
	case $initSystem in
		1)
			systemctl stop $SERVICE_NAME
			systemctl disable $SERVICE_NAME
			rm /etc/systemd/system/$SERVICE_NAME.service
			rm /usr/local/bin/$SIMPLY_NAME.sh
			systemctl daemon-reload
			systemctl reset-failed
		;;
		2)
			service $SERVICE_NAME stop
			update-rc.d $SERVICE_NAME remove 2>/dev/null
			if [ $? -eq 127 ]; then
				chkconfig --del dualconnector
			fi
			rm /etc/init.d/$SERVICE_NAME
		;;
	esac
	# delete jar library
	rm $INSTALL_PATH$SIMPLY_NAME.jar
	# delete bin files
	rm $INSTALL_PATH_BIN$DCCONSOLE.jar
	rm $INSTALL_PATH_BIN$DCCONSOLE
	rm $INSTALL_PATH_BIN$DCCONTROL.jar
	rm $INSTALL_PATH_BIN$DCCONTROL
	rm $INSTALL_PATH_BIN$DCUPDATER.jar
	rm $INSTALL_PATH_BIN$DCUPDATER
	#rm $CONFIG_PATH$CONFIG_FILE 
}

currentuser="$(id -u)"
if [ "$currentuser" != "0" ]; then
	echo "Please run as root"
	exit 0
else
	echo "Run as root"
fi

checkJava
if [ $checkinstalljava -eq 127 ]; then
	echo "Ошибка, не удалось найти java"
	exit 0
fi

checkInitSystem
if [ $initSystem -eq 127 ]; then
	echo "Ошибка, не удалось найти systemd и init.d"
else
	case $1 in
		install)
			install
		;;
		uninstall)
			uninstall
		;;
		update)
			uninstall
			install
		;;
		*)
			echo -e "Скрипт установки $SERVICE_NAME service\n\tinstall\t\t-\tустановка сервиса $SERVICE_NAME\n\tuninstall\t-\tудаление сервиса $SERVICE_NAME"
		;;
	esac 
fi


