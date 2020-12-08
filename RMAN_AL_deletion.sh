#!/bin/sh 

BASEDIR=$(dirname $0)
PROGNAME=$(basename $0)
DBNAME="TEST"
dte=`date '+%Y%m%d' | tr -d '\n'`
OPERATION="config-clone|pre-refresh|post-refresh|pre-snapshot|post-snapshot|pre-rewind|post-rewind|pre-start|post-stop"
LOGDIR="${BASEDIR}/${DBNAME}/logs"
LOGFILE="${LOGDIR}/${PROGNAME}.${hook_op}.log"
.  ${BASEDIR}/dxh_hook_profile.sh
.  ${BASEDIR}/dxh_hook_functions.sh

usage() {
   echo
   echo "Usage: $0 -o <hook_operation> "
   echo "Where: "
   echo "  -o ${OPERATION}"
   echo
   exit 1
}


echo "RMAN Archived Log(ALL) DELETION started at `date`" >>  $LOGFILE

$ORACLE_HOME/bin/rman nocatalog  <<EOF | tee  $LOGFILE
connect target /
run {
allocate channel dsk1 type disk MAXPIECESIZE=5G;
allocate channel dsk2 type disk MAXPIECESIZE=5G;
sql 'alter system archive log current';
CROSSCHECK ARCHIVELOG ALL;
delete force noprompt archivelog all completed before 'sysdate-7';
}
EOF

echo "RMAN Archived Log(ALL) backup finished at `date`" >>  $LOGFILE
log_echo "${PROGNAME} execution completed"
echo ""
