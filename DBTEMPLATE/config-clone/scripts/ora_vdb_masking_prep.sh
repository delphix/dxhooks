#!/bin/bash
#================================================================================
# File:		ora_vdb_masking_prep.sh
# Type:		korn-shell script
# Author:       Delphix field services
# Date:		19-June 2019
#
# Copyright and license:
#
#       Licensed under the Apache License, Version 2.0 (the "License"); you may
#       not use this file except in compliance with the License.
#
#       You may obtain a copy of the License at
#     
#               http://www.apache.org/licenses/LICENSE-2.0
#
#       Unless required by applicable law or agreed to in writing, software
#       distributed under the License is distributed on an "AS IS" basis,
#       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#
#       See the License for the specific language governing permissions and
#       limitations under the License.
#     
#       Copyright (c) 2019 by Delphix.  All rights reserved.
#
# Description:
#
#	Shell-script intended to be called from a Delphix "ConfigureClone" hook
#	to automatically perform several actions to prepare a "staging VDB" for
#	in-place masking...
#
#		
#		- display old UNDO settings prior to preparation for masking
#		- create new UNDO tablespace
#		- set UNDO_TABLESPACE = UNDO_DELPHIX_MASKING
#		- set UNDO_RETENTION = 86400
#		- set RECYCLEBIN = OFF
#		- SHUTDOWN IMMEDIATE
#		- STARTUP
#		- display new UNDO settings after preparation for masking
#		- disable FLASHBACK
#		- purge RECYCLEBIN
#
# Command-line parameters:
#
#	(none)
#
# Environment inputs expected:
#
#	ORACLE_SID
#	ORACLE_HOME
#
# Note:
#	This script was not written for RAC VDBs, only non-RAC VDBs.
#
# Modifications:
#	TGorman	19jun19	first version
#================================================================================
#
#--------------------------------------------------------------------------------
# Initialize program variables...
#--------------------------------------------------------------------------------
_pgmName="ora_vdb_masking_prep"
_dtStamp="`date '+%C%y%m%d_%H%M'`"
_logFile="/tmp/${_pgmName}_${ORACLE_SID}_${_dtStamp}.log"
_hostName="`hostname`"
_emailRcpt=""
_emailSubj="ERROR in Delphix hook script \"${_pgmName}.sh\""
#
#--------------------------------------------------------------------------------
# Verify that ORACLE_SID is set...
#--------------------------------------------------------------------------------
if [[ "${ORACLE_SID}" = "" ]]
then
	_msg="`date` - ERROR: ORACLE_SID not set; aborting..."
	echo "${_msg}"
	if [[ "${_emailRcpt}" != "" ]]
	then
		echo "${_msg}" | mailx -s "${_emailSubj}" ${_emailRcpt}
	fi
	exit 1
fi
#
#--------------------------------------------------------------------------------
# Verify that ORACLE_SID is up and running...
#--------------------------------------------------------------------------------
_isInstanceRunning="`ps -eaf | grep ora_pmon_${ORACLE_SID} | grep -v grep`"
if [[ "${_isInstanceRunning}" = "" ]]
then
	_msg="`date` - ERROR: database instance \"${ORACLE_SID}\" not running; aborting..."
	echo "${_msg}" | tee -a ${_logFile}
	if [[ "${_emailRcpt}" != "" ]]
	then
		echo "${_msg}" | mailx -s "${_emailSubj}" ${_emailRcpt}
	fi
	exit 1
fi
#
#--------------------------------------------------------------------------------
# Verify that ORACLE_HOME is set...
#--------------------------------------------------------------------------------
if [[ "${ORACLE_HOME}" = "" ]]
then
	_msg="`date` - ERROR: ORACLE_HOME not set; aborting..."
	echo "${_msg}" | tee -a ${_logFile}
	if [[ "${_emailRcpt}" != "" ]]
	then
		echo "${_msg}" | mailx -s "${_emailSubj}" ${_emailRcpt}
	fi
	exit 1
fi
#
#--------------------------------------------------------------------------------
# Verify that ORACLE_HOME refers to a directory...
#--------------------------------------------------------------------------------
if [ ! -d ${ORACLE_HOME} ]
then
	_msg="`date` - ERROR: ORACLE_HOME directory \"${ORACLE_HOME}\" not found; aborting..."
	echo "${_msg}" | tee -a ${_logFile}
	if [[ "${_emailRcpt}" != "" ]]
	then
		echo "${_msg}" | mailx -s "${_emailSubj}" ${_emailRcpt}
	fi
	exit 1
fi
#
#--------------------------------------------------------------------------------
# Verify that the SQL*Plus executable exists within the ORACLE_HOME...
#--------------------------------------------------------------------------------
if [ ! -x ${ORACLE_HOME}/bin/sqlplus ]
then
	_msg="`date` - ERROR: executable \"${ORACLE_HOME}/bin/sqlplus\" not found; aborting..."
	echo "${_msg}" | tee -a ${_logFile}
	if [[ "${_emailRcpt}" != "" ]]
	then
		echo "${_msg}" | mailx -s "${_emailSubj}" ${_emailRcpt}
	fi
	exit 1
fi
#
#--------------------------------------------------------------------------------
# Log the start of the script into the log file...
#--------------------------------------------------------------------------------
_msg="`date` - INFO: begin preparing \"${ORACLE_SID}\" (${ORACLE_HOME}) for masking..."
echo "${_msg}" | tee -a ${_logFile}
if [[ "${_emailRcpt}" != "" ]]
then
	echo "${_msg}" | mailx -s "${_emailSubj}" ${_emailRcpt}
fi
#
#--------------------------------------------------------------------------------
# Run SQL*Plus as SYSDBA to perform the following...
show parameter undo_tablespace
#--------------------------------------------------------------------------------
${ORACLE_HOME}/bin/sqlplus -S / as sysdba << __EOF0__ 2>&1 | tee -a ${_logFile}
whenever oserror exit failure rollback
whenever sqlerror exit failure rollback
set echo on feedback on timing on
prompt 
prompt display old UNDO settings prior to preparation for masking...
show parameter undo_retention
prompt
prompt create new UNDO tablespace...
create bigfile undo tablespace undo_delphix_masking datafile size 4G autoextend on next 1G maxsize 1024G retention guarantee;
prompt 
prompt set UNDO_TABLESPACE = UNDO_DELPHIX_MASKING...
alter system set undo_tablespace = 'UNDO_DELPHIX_MASKING' scope=spfile;
prompt 
prompt set UNDO_RETENTION = 86400...
alter system set undo_retention = 86400 scope=spfile;
prompt 
prompt set RECYCLEBIN = OFF...
alter system set recyclebin = off scope=spfile;
prompt 
prompt SHUTDOWN IMMEDIATE...
shutdown immediate
prompt 
prompt STARTUP...
startup
prompt 
prompt display new UNDO settings after preparation for masking...
show parameter undo_tablespace
show parameter undo_retention
prompt 
prompt disable FLASHBACK...
alter database flashback off;
prompt 
prompt purge RECYCLEBIN...
purge dba_recyclebin;
exit success commit
__EOF0__
if (( $? != 0 ))
then
	_msg="`date` - ERROR: SQL*Plus session failed, check \"${_logFile}\" on database host \"${_hostName}\"; aborting..."
	echo "${_msg}" | tee -a ${_logFile}
	if [[ "${_emailRcpt}" != "" ]]
	then
		echo "${_msg}" | mailx -s "${_emailSubj}" ${_emailRcpt}
	fi
	exit 1
fi
#
#--------------------------------------------------------------------------------
# Record the successful completion of the script to the log file...
#--------------------------------------------------------------------------------
_msg="`date` - INFO: completed preparing \"${ORACLE_SID}\" (${ORACLE_HOME}) for masking"
echo "${_msg}" | tee -a ${_logFile}
if [[ "${_emailRcpt}" != "" ]]
then
	echo "${_msg}" | mailx -s "${_emailSubj}" ${_emailRcpt}
fi
exit 0
