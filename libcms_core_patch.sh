#!/bin/bash

path=$(pwd)
libcms=( "$path"/libcms_core.so_*_save )

offset=$(strings -t d $libcms | grep "M 1492" | awk '{print $1}')

echo -n "%s -M 1500" > mtu

cp $libcms "${libcms}_original"

dd if=mtu of=$libcms obs=1 seek=$offset conv=notrunc

