REM sample script to recreate tempfiles after cloning from Amazon RDS Oracle
alter trigger rdsadmin.rds_ddl_trigger2 disable;
alter trigger rdsadmin.rds_ddl_trigger disable;
alter tablespace temp add tempfile '/<MY_DATAFILE_PATH>/temp01.dbf' size 2000M;
alter trigger rdsadmin.rds_ddl_trigger2 enable;
alter trigger rdsadmin.rds_ddl_trigger enable;

