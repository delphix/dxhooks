REM sample script to create user
create user testuser1 identified by delphix default tablespace users;
grant resource, connect to testuser1;
REM create table, synonym
create table testuser1.employees_copy as select * from delphixdb.employees;
create synonym testuser1.employees for delphixdb.employees;
