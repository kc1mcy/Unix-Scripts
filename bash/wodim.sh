#!/bin/bash
#echo name: $0
#echo No: $#
#echo Args: $@
if test $# -eq 2
then 
  wodim -v speed=1 driveropts=burnfree dev=/dev/$1 fs=8m $2
else 
  echo
  echo  useage: wodim.sh device image
  #echo Args: $@
fi
