rm -f $SQLDIR/../../post-refresh/sql/dxh_set_grants_allusers_new.sql 
{
sqlplus -s "/ as sysdba"  <<EOF
SET HEADING OFF;
SET FEEDBACK OFF;
SET LINESIZE 300;
REM ALTER SESSION SET CONTAINER =$DELPHIX_PDB_NAME;
ALTER SESSION SET CONTAINER =$1;
SELECT username from dba_users where ORACLE_MAINTAINED='N' and username not like 'C##%' and username not like 'PDBADMIN'; 
EOF
} | while read line
do
  if [ "$line" ] # Line not NULL
  then 
sqlplus -s "/ as sysdba"  @$SQLDIR/dxh_extract_all_users_MT.sql $line $1
fi    
done
