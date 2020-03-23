#!/bin/sh
#Perform the dump
echo "[i] Perform the dump..."
dmp_file="/data/local/tmp/memory-dump.hprof"
am dumpheap $1 $dmp_file
sleep 5
#Wait the data to be written
echo "[i] Wait the data to be written..."
size=`wc -l $dmp_file | cut -d' ' -f1`
while [ $size -le 0 ]
do                                                                                                                         
	sleep 5                                                                                                                 
	size=`wc -l $dmp_file | cut -d' ' -f1`
done
echo "[i] Dump file created."