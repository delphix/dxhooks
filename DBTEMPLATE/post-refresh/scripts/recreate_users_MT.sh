sqlplus -s "/ as sysdba"  <<EOF
ALTER SESSION SET CONTAINER =$1;
@$SQLDIR/dxh_set_ddl_grants_allusers_MT.sql
EOF
