#! /bin/bash

# Close any TDCserver instances in case it is running already.
processID=$(pidof TDCserver)
echo $processID
if ! [ -z "$processID" ]
then
	echo "Killing running TDCserver process."
	kill -9 "$processID"
fi

./PLclock
cat TDCsystem_wrapper.bit > /dev/xdevcfg
gcc -o ../build/TDCserver TDCserver2.c
../build/TDCserver
