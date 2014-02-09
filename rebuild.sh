#!/usr/bin/env sh

. ./config.sh

for p in `ls $PATCHES`; do

	echo "========== building $p ==========="

	mkdir -p $LOGS/$p
	rm -Rf $BUILDS/$p

	cd $REPOSITORY

	echo "========== resetting repository ============"
	git reset --hard origin/master > $LOGS/$p/git-reset.log 2>&1
	if [ $? -ne 0 ]; then
		echo "git reset failed"
		exit 1
	fi

	git clean -f > $LOGS/$p/git-clean.log 2>&1
        if [ $? -ne 0 ]; then
                echo "git clean failed"
                exit 1
        fi

	git checkout `git rev-list -n 1 --before="$DATE" master` > $LOGS/$p/git-checkout.log 2>&1
        if [ $? -ne 0 ]; then
                echo "git checkout failed"
                exit 1 
        fi

	echo "========== applying patches ==========="
	for f in `ls $PATCHES/$p`; do

		echo "========== applying $p/$f ============"
		patch -p1 < $PATCHES/$p/$f >> $LOGS/$p/patch.log 2>&1
	        if [ $? -ne 0 ]; then
        	        echo "applying $f failed"
                	exit 1
	        fi

	done

	echo "========== rebuilding =============="
	./configure --prefix=$BUILDS/$p > $LOGS/$p/config.log 2>&1
        if [ $? -ne 0 ]; then
                echo "configure failed"
                exit 1
        fi

	make > $LOGS/$p/make.log 2>&1
        if [ $? -ne 0 ]; then
                echo "make failed"
                exit 1
        fi

	make install > $LOGS/$p/install.log 2>&1
        if [ $? -ne 0 ]; then
                echo "make install failed"
                exit 1
        fi

done
