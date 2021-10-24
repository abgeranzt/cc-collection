#!/bin/sh

for d in .local/computer/*; do
	ln -sf src $d/src
done
