#!/bin/bash

COUNTER=1 ; while [ $COUNTER -lt 23 ] ; do echo "Chr"$COUNTER >> chromosome.list ; let COUNTER=$COUNTER+1; done
echo "ChrX" >> chromosome.list
echo "ChrY" >> chromosome.list
echo "ChrMT" >> chromosome.list

