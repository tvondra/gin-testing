#!/bin/env sh

HOMEDIR=`realpath "$0"`
HOMEDIR=`dirname "$HOMEDIR"`
export HOMEDIR

export PATCHES="$HOMEDIR/patches"
export REPOSITORY="/home/tomas/work/postgres"
export BUILDS="$HOMEDIR/builds"
export LOGS="$HOMEDIR/logs"
export DATE="2014-02-01 00:00"
export DATA="$HOMEDIR/pgdata"
export DATASET="$HOMEDIR/data"
export RESULTS="$HOMEDIR/results"

echo $HOMEDIR
