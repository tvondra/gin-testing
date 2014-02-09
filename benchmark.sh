#!/bin/bash

. ./config.sh

PATH_tmp=$PATH

for b in `ls $BUILDS`; do

	echo "====== benchmarking $b ========="

	# make sure no clusters are running
	killall -9 postgres >> /dev/null 2>&1

	sleep 10

	rm -Rf $RESULTS/$b
	rm -Rf $DATA

	mkdir -p $LOGS/$b
	mkdir -p $RESULTS/$b

	PATH=$BUILDS/$b/bin:$PATH_tmp

	echo "===== init & start of the cluster ======"
	pg_ctl -D $DATA -l $LOGS/$b/pg.log init > $LOGS/$b/init.log 2>> $LOGS/$b/init.err
	if [ $? -ne 0 ]; then echo "cluster init failed"; exit 1; fi

	sleep 20

	cp postgresql.conf $DATA
	pg_ctl -D $DATA -l $LOGS/$b/pg.log start >> $LOGS/$b/start.log 2>> $LOGS/$b/start.err
	if [ $? -ne 0 ]; then echo "cluster start failed"; exit 1; fi

	sleep 10

	# collect some stats first, so that we know it's the right version / settings later
	pg_config > $LOGS/$b/config.log 2> $LOGS/$b/config.err
	psql postgres -c "SELECT * FROM pg_settings ORDER BY setting" > $LOGS/$b/settings.log 2> $LOGS/$b/settings.err

	echo "===== loading data ====="
	createdb -h localhost test >> $LOGS/$b/createdb.log 2>&1
	if [ $? -ne 0 ]; then echo "createdb failed"; exit 1; fi

	psql test -c "CREATE TABLE messages(body_tsvector tsvector)" >> $LOGS/$b/load.log 2>> $LOGS/$b/load.err
	if [ $? -ne 0 ]; then echo "CREATE TABLE failed"; exit 1; fi

	psql test -c "COPY messages FROM '$DATASET/messages.data'" >> $LOGS/$b/load.log 2>> $LOGS/$b/load.err
	if [ $? -ne 0 ]; then echo "COPY failed"; exit 1; fi

	psql test -c "CREATE INDEX messages_idx ON messages USING GIN(body_tsvector)" >> $LOGS/$b/load.log 2>> $LOGS/$b/load.err
	if [ $? -ne 0 ]; then echo "CREATE INDEX failed"; exit 1; fi

	psql test -c "VACUUM (FULL, FREEZE, ANALYZE) messages" >> $LOGS/$b/load.log 2>> $LOGS/$b/load.err
	if [ $? -ne 0 ]; then echo "VACUUM failed"; exit 1; fi

	# run the queries
	echo "===== running queries ======"
	for s in `ls querysets`; do
		for i in `seq 1 10`; do
			echo "===== running $s / batch $i ======"
			psql test -c "\i querysets/$s" > $RESULTS/$b/$s.$i 2> $RESULTS/$b/$s.$i.err
		done
	done

	pg_ctl -D $DATA -m fast stop
	sleep 5

	rm -Rf $DATA

done
