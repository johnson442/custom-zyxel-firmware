#!/bin/bash

logSize=5759

logFile="/var/tmp/stats/data/logfile"

statsFile="/var/tmp/stats/data/varStats"

updateInterval=30


lastFecDown=0
lastFecUp=0
lastCrcDown=0
lastCrcUp=0

lastTime=0

firstRun=true

firstTimeStamp=true

sleep 40

while [ 1 ]
do

    xdslctl info --stats > $statsFile

    lineActive=$(awk '/^Status/ {if ($2 == "Showtime") print "true";
                        else print "false";exit}' $statsFile)

    numlines=$(wc -l $logFile | awk '{ print $1 }')
    timeStamp=$(date +"%s")
    
    
    #lastTimeAwk=$(awk 'END {print $1; exit}' $logFile)
    #echo $lastTimeAwk
    
    timeDiff=0
    
    if [ $firstTimeStamp = false ]
    then
        timeDiff=$((timeStamp-lastTime))
    else
        firstTimeStamp=false
    fi
    
    needUpdate=false
    
    if [ $timeDiff -gt 600 ]
    then
        needUpdate=true
    elif [ $timeDiff -lt -600 ]
    then
    	needUpdate=true
    fi
    
    if [ $needUpdate = "true" ]
    then
	timeDiff=$((timeDiff-30))
    	awk -v x=$timeDiff ' {$1=$1+x} {print} ' $logFile > "${logFile}Time"
    	mv "${logFile}Time" $logFile
    fi
    
    lastTime=$timeStamp
    

    if [ $lineActive = "true" ]
    then
        #echo "Got showtime"

        snrValues=$(awk '/^SNR/ {print $3,$4; exit}' $statsFile)
        fecValues=$(awk '/^FEC/ {print $2,$3; exit}' $statsFile)
        crcValues=$(awk '/^CRC/ {print $2,$3; exit}' $statsFile)


        fecDown=$(echo $fecValues | awk '{ print $1 }')
        fecDownDiff=$((fecDown-lastFecDown))
        lastFecDown=$fecDown

        fecUp=$(echo $fecValues | awk -v RS='\r' '{ print $2 }')
        fecUpDiff=$((fecUp-lastFecUp))
        lastFecUp=$fecUp

        crcDown=$(echo $crcValues | awk '{ print $1 }')
        crcDownDiff=$((crcDown-lastCrcDown))
        lastCrcDown=$crcDown

        crcUp=$(echo $crcValues | awk -v RS='\r' '{ print $2 }')
        crcUpDiff=$((crcUp-lastCrcUp))
        lastCrcUp=$crcUp

        if [ $firstRun = false ]
        then
            if [[ $numlines -gt $logSize ]]
            then
                tail -n +2 $logFile > "${logFile}Tmp" && mv "${logFile}Tmp" $logFile
            fi

            echo "$timeStamp $snrValues $fecDownDiff $fecUpDiff $crcDownDiff $crcUpDiff" >> $logFile
        else
            firstRun=false
        fi

        sleep $updateInterval

    else

        if [[ $numlines -gt $logSize ]]
        then
            tail -n +2 $logFile > "${logFile}Tmp" && mv "${logFile}Tmp" $logFile
        fi

        echo "$timeStamp NOSYNC" >> $logFile

        sleep $updateInterval
    fi


done


