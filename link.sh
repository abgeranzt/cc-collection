#!/bin/sh

n=$(grep -m 1 'computer' < .local/ids.json | sed 's/[^0-9]//g')

for f in .local*; do 
	for i in $(seq 0 $n); do
		mkdir -p ${f}/computer/$i
		d=${f}/computer/$i/src
		if [ ! -e $d ]; then
			ln -s $(pwd)/src $d
		fi
	done
done
