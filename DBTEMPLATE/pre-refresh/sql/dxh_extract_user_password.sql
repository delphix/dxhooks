
set head off
set pages 0
set long 9999999
spool ${SQLDIR}/../../post-refresh/sql/dxh_reset_user_password.sql
REM http://www.dba-oracle.com/t_save_reset_oracle_user_password.htm
select 'alter user "'||username||'" identified by values '''||extract(xmltype(dbms_metadata.get_xml('USER',username)),'//USER_T/PASSWORD/text()').getStringVal()||''';'  old_password 
from dba_users where username in ('DELPHIX', 'HR');
spool off


