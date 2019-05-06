#!/bin/bash

COUNTER=1 ; while [ $COUNTER -lt 23 ] ; do echo "chr"$COUNTER >> chromosome.list ; let COUNTER=$COUNTER+1; done
echo "chrX" >> chromosome.list
echo "chrY" >> chromosome.list
echo "chrMT" >> chromosome.list

