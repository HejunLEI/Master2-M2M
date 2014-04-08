#!/bin/sh

MYVERRYOWNPATH=/home/root/mosquitto-1.3.1/client
MYVERYOWNVALUE=2

if [ $# -eq 0 ] ; then
	echo "usage: $0 <ip address>"
	exit;
fi

# init
echo -n "37" > /sys/class/gpio/export		# A0
echo -n "out" > /sys/class/gpio/gpio37/direction
echo -n "0" > /sys/class/gpio/gpio37/value

# loop
while true ; do
	TOSEND="";

	A0=`cat /sys/bus/iio/devices/iio\:device0/in_voltage0_raw`
	
	if [ $A0 -gt 25 ] ; then
		TOSEND="ON"
	else
		TOSEND="OFF"
	fi

	if [ $MYVERYOWNVALUE != $TOSEND ] ; then
		$MYVERRYOWNPATH/mosquitto_pub -h $1 -t smokedetector -m "$TOSEND"
		MYVERYOWNVALUE=$TOSEND
	fi
done
