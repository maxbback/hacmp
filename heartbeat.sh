#!/bin/bash

#D Instructions
#D make this program a deamon service
#D Add following to /etc/systemd/system/mydaemon.service
#D [Unit]
#D Description=Monitor application
#D 
#D [Service]
#D ExecStart=/xxxx/heartbeat.sh
#D Restart=on-failure
#D 
#D [Install]
#D WantedBy=multi-user.target
#
#

#D variable pgrepProgramName holds search string for the program to monitor 
pgrepProgramName='sh.*exmapleApplication.sh.*'

#D variable startCmd contains information of how to start the program
startCmd='./exmapleApplication.sh'
startCmdLogFile='./startCmdLogFile.log'

#D variable maintenanceFile is the location of a maintenance file, which will make this program stop monitoring
maintenanceFile='./maintenance'

#D variable hostName contains information of the local hostname
hostName=`hostname`

#D variable heartBeatDir defines where HB files are stored, a HB file has the name of the host running the program
heartBeatDir='heartbeat'

#D variable faileOverTime defines how long time we wait for a heartbeat before we consider it dead
faileOverTime=10

#D variable loopTime defines how long each monitor sleep time should be, prefereable 1/3 of failOverTime
loopTime=3


#D function sendIncident notifies that we was soposed to be up but has died
function sendIncident
{
	echo "####"
	echo "#### ERROR, we sent last heartbeat but is not alive"
	echo "####"
}

#D function isAlive test if monitored program is running
function isAlive
{
	#D Check if at least one process is running
	pgrep -f "$pgrepProgramName" 
	return $?
}

# function hasHeartBeat takes a hostname and checks if that host is alive av run the monitored program
function hasHeartBeat
{
	#First argument is the host to monitor
	local hbHostName="$1"
	if [ -z "$hbHostName" ]
	then
		#echo hasHeartBeat argument missing
		return 1
	fi
	if [ ! -f $heartBeatDir/$hbHostName ]
	then
		#echo hasHeartBeat HB file not found $heartBeatDir/$hbHostName
		return 1
	fi
	# stat checks the status of a specific file
	# eval sets variables for each result from stat, st_mtime contains last modified time
	eval $(stat -s $heartBeatDir/$hbHostName)
	st_mtime=`stat -c %Y $heartBeatDir/$hbHostName`
	curentTime=`date +%s`
	echo $curentTime
	echo $st_mtime
	echo $(($curentTime - $st_mtime))
	echo $(($curentTime - $st_mtime - $faileOverTime))
	if [ $(($curentTime - $st_mtime - $faileOverTime)) -lt 0 ]
	then
		echo "Instance is alive on node $1"
		return 0
	else
		echo "Instance down"
		return 1
	fi
}


function killInstance
{
	echo "Killing server Instance"
	#D find all running instanes and stop them nicly
	pgrep -f "$pgrepProgramName" | while read pid
	do
		kill $pid
	done
	#D wait 30 seconds for processes to die before we kill them hard
	sleep 30
	#D find all running instanes and kill them
	pgrep -f "$pgrepProgramName" | while read pid
	do
		kill -9 $pid
	done

}

function startInstance
{	
	echo "in Starting server"
	echo "Sleep 5 second to give room for avoiding conflicts"
	sleep 5
	echo "Check if we are still master"
	latestHB=`ls -1tr $heartBeatDir|tail -1`

	if [ "$latestHB" == "$hostName" ]
	then
		echo "We are master so start server"
		nohup $startCmd > $startCmdLogFile 2>&1 &
	fi
	
}

#Main
echo "starting monitoring"

while [ 1 ]
do
	echo "In monitoring loop sleep $loopTime"
	sleep $loopTime
	if [ -f $maintenanceFile ]
	then
		echo "We are in maintenance mode, so we do nothing"
		continue
	fi

	latestHB=`ls -1tr $heartBeatDir|tail -1`
	#echo "last HB sent By :$latestHB:"

	if [ "$latestHB" == "" ]
	then
		#echo "No master, lets be master"
		touch $heartBeatDir/$hostName
		startInstance
		continue
	else
		#are we master?
		if [ "$latestHB" == "$hostName" ]
		then
			# We sent last heart beat, check if we are alive
			isAlive
			if [ $? -eq 0 ]
			then
				# echo "we sent last HB and is alive"
				touch $heartBeatDir/$hostName
				continue
			fi
			# echo "we have died, sent incident notification"
			sendIncident
			# echo "We will sleep 2 * failoverTime to allow someone else take over before we try to start up"
			sleep $faileOverTime
			sleep $faileOverTime
		else
			echo "We are not master, so kill any running instances"
			killInstance
		fi
	fi

	# Collect new status of last heartbeat
	latestHB=`ls -1tr $heartBeatDir|tail -1`
	echo $latestHB
	echo "checking last heartbeat if we shll tak eover"

	hasHeartBeat $latestHB
	hostAlive=$?
	if [ $hostAlive -eq 1 ]
	then
		echo "no master taking over"
		echo "trying to be master"
		touch $heartBeatDir/$hostName
		startInstance
	fi
done
