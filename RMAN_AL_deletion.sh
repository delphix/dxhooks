#!/bin/sh 

BASEDIR=$(dirname $0)
PROGNAME=$(basename $0)
DBNAME=""
dte=`date '+%Y%m%d' | tr -d '\n'`
OPERATION="config-clone|pre-refresh|post-refresh|pre-snapshot|post-snapshot|pre-rewind|post-rewind|pre-start|post-stop"
for i in $*
do
   case $1 in
      -o) hook_op=$2; shift 2;;
      -d) DBNAME=$2; shift 2;;
      -*) usage; exit 1;;
   esac
done

if [ $(echo ${hook_op} | egrep -c ${OPERATION}) -eq 0 ]; then
   usage
   exit 1
fi
LOGDIR="${BASEDIR}/${DBNAME}/logs"
LOGFILE="${LOGDIR}/${PROGNAME}.${hook_op}.log"
. ${BASEDIR}/dxh_hook_profile.sh
. ${BASEDIR}/dxh_hook_functions.sh

echo "RMAN Archived Log(ALL) DELETION started at `date`" >>  $LOGFILE
$ORACLE_HOME/bin/rman nocatalog  <<EOF | tee  $LOGFILE
connect target /
run {
allocate channel dsk1 type disk MAXPIECESIZE=5G;
allocate channel dsk2 type disk MAXPIECESIZE=5G;
sql 'alter system archive log current';
CROSSCHECK ARCHIVELOG ALL;
delete force noprompt archivelog all completed before 'sysdate-2';
}
EOF

echo "RMAN Archived Log(ALL) backup finished at `date`" >>  $LOGFILE
log_echo "${PROGNAME} execution completed"
echo ""
