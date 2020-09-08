#!/bin/bash

while true; do
	psql -c 'call refresh_log();'
	sleep 1
done
