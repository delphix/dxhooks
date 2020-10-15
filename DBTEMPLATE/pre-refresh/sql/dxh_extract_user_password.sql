
set head off
set pages 0
set long 9999999
set lin 999
set longc 9999999
set feed off
spool ${SQLDIR}/../../post-refresh/sql/dxh_reset_user_password.sql
REM Adopted from Ask Tom: https://asktom.oracle.com/pls/apex/f?p=100:11:0::::P11_QUESTION_ID:9537400300346732900
with t as
  ( select dbms_metadata.get_ddl('USER',username) ddl
    from dba_users where username in ('DELPHIX', 'HR')
  )
select replace(substr(ddl,1,instr(ddl,'DEFAULT')-1),'CREATE','ALTER')||';'
from t;
spool off




