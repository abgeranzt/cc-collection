#!/bin/sh

n=$(grep -m 1 'computer' < .local/ids.json | sed 's/[^0-9]//g')

for i in $(seq 0 $n); do
	mkdir -p .local/computer/$i
	d=.local/computer/$i/ccc
	if [ ! -e $d ]; then
		ln -s $(pwd)/src $d
	fi
done
