set heading off trimspool on feedback off pages 10000 lines 120 verify off
spool ${SQLDIR}/../../post-refresh/sql/dxh_extract_grants_users.sql
select 'grant '||privilege||' to '||grantee||';' from dba_sys_privs where grantee in ('DELPHIX') order by grantee,privilege;
select 'grant '||privilege||' on '||owner||'.'||table_name||' to '||grantee||';' from dba_tab_privs where grantee in ('DELPHIX')  order by grantee,table_name,privilege;
select 'grant '||granted_role||' to '||grantee||';' from dba_role_privs where grantee in ('DELPHIX') order by grantee,granted_role;
spool off

