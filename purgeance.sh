#!/bin/sh
sudo chown leseb /tmp/purgeance.txt
#ps aux | grep VLC | sed -n '1p' | grep VLC.app

x=$(ps aux | grep VLC.app | wc -l | awk '{print $1}')
if [ $x -eq 1 ] ; then
	purge
	if [ $? -eq 0 ] ; then
		echo "`date` purge success" >> /tmp/purgeance.txt
	fi
else
	echo "`date` vlc est ouvert !" >> /tmp/purgeance.txt
fi
