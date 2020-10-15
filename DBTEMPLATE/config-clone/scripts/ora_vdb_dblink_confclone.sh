#!/bin/bash
#================================================================================
# File:		ora_vdb_dblink_confclone.sh
# Type:	 	bash-shell script
# Date:	 	07-Aug 2018
# Author:	Delphix
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright (c) 2018 by Delphix. All rights reserved.
# 
# Description:
#
#	This script is intended to be called from a Delphix Configure Clone
#	hook, which will execute after the initial provision of a VDB, and
#	again after each refresh.
#
#	This script can also be called by a DBA following the initial provision
#	of a Delphix VDB only, so that it is not called after each refresh.
#
#	The script will drop and recreate all database links with a false
#	user account password (i.e. IDENTIFIED BY clause) and a false TNS
#	specification (i.e. USING clause), to ensure that database links cannot
#	connect back to the production environment.
#
# Calling syntax:
#
#       ora_vdb_dblink_confclone.sh $ORACLE_SID $ORACLE_HOME recompile-degree [ repeat-filename ]
#
# Calling parameters:
#
#	$ORACLE_SID	- the ORACLE_SID environment variable expanded value
#	$ORACLE_HOME	- the ORACLE_HOME environment variable expanded value
#	recompile-degree	0 - do not recompile any invalid objects
#				1 - recompile any invalid objects serially
#				NN - recompile any invalid objects in parallel
#				     using degree "NN"
#	repeat-filename	- the name of a file to contain the VDB info each time
#			this script is executed.  If this parameter is not
#			specified, then the script will execute all logic each
#			time it is called.  If this parameter is specified, then
#			the script will execute all logic only the first time
#			it is called, and not on any of the subsequent calls
#
# Modifications:
#	TGorman	07aug18	written
#================================================================================
#
#--------------------------------------------------------------------------------
# Validate command-line parameters...
#--------------------------------------------------------------------------------
case $# in
	4)	_repeatFileName=$4
		typeset -i _reCompileDegree=$3
		export ORACLE_HOME=$2
		export ORACLE_SID=$1
		;;
	3)	_repeatFileName=""
		typeset -i _reCompileDegree=$3
		export ORACLE_HOME=$2
		export ORACLE_SID=$1
		;;
	*)	echo "Usage: \"$0 \$ORACLE_SID \$ORACLE_HOME recompile-degree [ repeat-filename]\"; aborting..."
		exit 1
		;;
esac
#
#--------------------------------------------------------------------------------
# Validate the value of "recompilation degree of parallelism"...
#--------------------------------------------------------------------------------
if (( ${_reCompileDegree} < 0 || ${_reCompileDegree} > 99 ))
then
	echo "Usage: \"$0 \$ORACLE_SID \$ORACLE_HOME recompile-degree\"; aborting..."
	echo "recompile-degree must be between 0 (do not recompile) and 99"
	exit 1
fi
#
#--------------------------------------------------------------------------------
# Set pathname and name of generated SQL*Plus scripts to be used later in this
# script...
#--------------------------------------------------------------------------------
_workDir=/tmp
_outFile=${_workDir}/ora_vdb_dblink_confclone_${ORACLE_SID}.lst
_recreateDBLinkScript=${_workDir}/recreate_${ORACLE_SID}_dblinks
_reCompileOut=${_workDir}/recomp_${ORACLE_SID}_all
#
#--------------------------------------------------------------------------------
# Verify that the ORACLE_SID value is valid and the instance is up and running...
#--------------------------------------------------------------------------------
_instanceUp=`ps -eaf | grep "ora_pmon_${ORACLE_SID}$" | grep -v grep | wc -l`
if (( ${_instanceUp} == 0 )) 
then
	echo "`date` ORACLE_SID=\"${ORACLE_SID}\" - no running instance; aborting..."
	exit 1
fi
#
#--------------------------------------------------------------------------------
# Verify that the provided ORACLE_HOME value exists as a readable directory and
# that there is an executable SQL*Plus within it...
#--------------------------------------------------------------------------------
if [ ! -d ${ORACLE_HOME} ]
then
	echo "`date` ORACLE_HOME=\"${ORACLE_HOME}\" not found; aborting..."
	exit 1
fi
if [ ! -d ${ORACLE_HOME}/bin ]
then
	echo "`date` ORACLE_HOME subdirectory \"${ORACLE_HOME}/bin\" not found; aborting..."
	exit 1
fi
if [ ! -d ${ORACLE_HOME}/lib ]
then
	echo "`date` ORACLE_HOME subdirectory \"${ORACLE_HOME}/lib\" not found; aborting..."
	exit 1
fi
if [ ! -x ${ORACLE_HOME}/bin/sqlplus ]
then
	echo "`date` executable \"${ORACLE_HOME}/bin/sqlplus\" not found; aborting..."
	exit 1
fi
#
#--------------------------------------------------------------------------------
# Set the LD_LIBRARY_PATH environment variable, as generally SQL*Plus needs it...
#--------------------------------------------------------------------------------
export LD_LIBRARY_PATH=${ORACLE_HOME}/lib
#
#--------------------------------------------------------------------------------
# Generate the invalid-object recompilation command as requested...
#  0  - do not recompile
#  1  - recompile serially
#  NN - recompile in parallel using degree NN
#--------------------------------------------------------------------------------
case "${_reCompileDegree}" in
	0)	_reCompileCmd="prompt No object recompilation requested" ;;
	1)	_reCompileCmd="exec utl_recomp.recomp_serial();" ;;
	*)	_reCompileCmd="exec utl_recomp.recomp_parallel(${_reCompileDegree});" ;;
esac
#
#--------------------------------------------------------------------------------
# if this script's optional 4th command-line parameter was specified, then the
# value should be the name of a file.
#
# If the specified file-name exists, then its contents should consist of the
# following column values from V$DATABASE from the VDB...
#
#	1) DBID
#	2) RESETLOGS_CHANGE#
#	3) PRIOR_RESETLOGS_CHANGE#
#
# if the specified file exists and it contents match, then exit the script
# normally, because it has already been executed once.
#--------------------------------------------------------------------------------
if [[ "${_repeatFileName}" != "" ]]
then
	#
	#------------------------------------------------------------------------
	# Query V$DATABASE for DBID, RESETLOGS_CHANGE#, and
	# PRIOR_RESETLOGS_CHANGE# values...
	#------------------------------------------------------------------------
	${ORACLE_HOME}/bin/sqlplus -L -S / as sysdba << __EOF0__ > ${_outFile} 2>&1
whenever oserror exit failure
whenever sqlerror exit failure
set echo off feedback off timing off pause off pagesize 0 linesize 500 trimout on trimspool on
select	trim(to_char(dbid,'999999999999999'))||','||
	trim(to_char(resetlogs_change#,'999999999999999'))||','||
	trim(to_char(prior_resetlogs_change#,'999999999999999'))
from	v\$database;
exit success
__EOF0__
	if (( $? != 0 ))
	then
		echo "`date` SQL*Plus to query V$DATABASE failed; aborting..."
		echo "Please review spooled output file \"${_outFile}\""
		exit 1
	fi
	#
	#------------------------------------------------------------------------
	# If a "repeat file" is found, then pull its contents into a script
	# variable and compare those contents to the query that just completed...
	#------------------------------------------------------------------------
	if [ -f ${_repeatFileName} ]
	then
		_previousValue=`cat ${_repeatFileName}`
		_currentValue=`cat ${_outFile}`
		if [[ "${_previousValue}" = "${_currentValue}" ]]
		then
			echo "`date` contents of repeat file \"${_repeatFileName}\" MATCH previous contents; exiting normally..."
			exit 0
		fi
	fi
	#
	#------------------------------------------------------------------------
	# store the information just retrieved from the VDB into the "repeat
	# file"...
	#------------------------------------------------------------------------
	mv ${_outFile} ${_repeatFileName}
	if (( $? != 0 ))
	then
		echo "`date` \"mv ${_outFile} ${_repeatFileName}\" failed; aborting..."
		echo "This script should be able to write to \"${_repeatFileName}\""
		exit 1
	fi
fi
#
#--------------------------------------------------------------------------------
# Run SQL*Plus to generate another SQL*Plus script to recreate all of the existing
# database links with invalid connection information...
#--------------------------------------------------------------------------------
${ORACLE_HOME}/bin/sqlplus -L -S / as sysdba << __EOF1__ > ${_outFile} 2>&1
col right_now new_value V_RIGHT_NOW noprint
select to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS') right_now from dual;
prompt SYSDATE is &&V_RIGHT_NOW....
whenever oserror exit failure
whenever sqlerror exit failure
set echo off feedback off timing off pagesize 0 linesize 500 trimout on trimspool on
col sort0 noprint
col sort1 noprint
col sort2 noprint
col txt format a500
spool ${_recreateDBLinkScript}.sql
prompt REM Generating and running script to recreate all existing database links...
prompt set echo on feedback on timing on trimout on trimspool on termout on
prompt whenever sqlerror exit failure
prompt whenever oserror exit failure
prompt spool ${_recreateDBLinkScript}.lst
prompt 
select	0 sort0,
	to_char(u.user#) sort1,
	l.name sort2,
	'whenever sqlerror continue'||chr(10)||
	'drop public database link '||
	'"'||l.name||'";'||chr(10)||
	'whenever sqlerror exit failure'||chr(10)||
	'create'||
	decode(l.flag,3,' shared','')||
	' public database link '||
	'"'||l.name||'"'||
	decode(l.userid,'','',chr(10)||chr(9)||'connect to "'||l.userid||'"')||
	decode(l.passwordx,'','',chr(10)||chr(9)||' identified by abc123def456ghi789jkl0')||
	decode(l.flag,3,chr(10)||chr(9)||'authenticated by "'||l.authusr||'"')||
	decode(l.flag,3,decode(l.authpwdx,'','',chr(10)||chr(9)||'identified by abc123def456ghi789jkl0'),'')||
	decode(l.host,'','',chr(10)||chr(9)||' using ''NOTxAxVALIDxTNSxSTRING''')||';'||
	chr(10) txt
from	link$ l, user$ u
where	l.owner# = u.user#
and	u.name in ('PUBLIC')
union all
select	1 sort0, '' sort1, '' sort2, 'whenever sqlerror exit failure' txt from dual
union all
select	2 sort0,
	u.name sort1,
	l.name sort2,
	'create procedure "'||u.name||'".delphix##_refresh##'||trim(to_char(row_number() over (partition by 2 order by u.name, l.name),'0000'))||' as'||
	chr(10)||chr(9)||'v_str     varchar2(1000);'||
	chr(10)||'begin'||
	chr(10)||chr(9)||'begin'||
	chr(10)||chr(9)||chr(9)||'v_str := '''||
	'drop database link '||
	'"'||l.name||'"'';'||
	chr(10)||chr(9)||chr(9)||'execute immediate v_str;'||
	chr(10)||chr(9)||'exception when others then null;'||
	chr(10)||chr(9)||'end;'||
	chr(10)||chr(9)||'v_str := '''||
	'create'||
	decode(l.flag,3,' shared','')||
	' database link '||
	'"'||l.name||'"''||'||
	decode(l.userid,'','',chr(10)||chr(9)||chr(9)||chr(9)||''' connect to "'||l.userid||'"''||')||
	decode(l.passwordx,'','',chr(10)||chr(9)||chr(9)||chr(9)||''' identified by abc123def456ghi789jkl0''||')||
	decode(l.flag,3,chr(10)||chr(9)||chr(9)||chr(9)||chr(9)||''' authenticated by "'||l.authusr||'"''||')||
	decode(l.flag,3,decode(l.authpwdx,'','',chr(10)||chr(9)||chr(9)||chr(9)||''' identified by abc123def456ghi789jkl0''||'))||
	decode(l.host,'','',chr(10)||chr(9)||chr(9)||chr(9)||''' using ''''NOTxAxVALIDxTNSxSTRING''''''')||';'||
	chr(10)||chr(9)||'execute immediate v_str;'||
	chr(10)||'end;'||
	chr(10)||'/'||
	chr(10)||'show errors'||
	chr(10) txt
from	link$ l, user$ u
where	l.owner# = u.user#
and	u.name not in ('PUBLIC')
union all
select	3 sort0,
	u.name sort1,
	l.name sort2,
	'exec "'||u.name||'".delphix##_refresh##'||trim(to_char(row_number() over (partition by 3 order by u.name, l.name),'0000'))||';' txt
from	link$ l, user$ u
where	l.owner# = u.user#
and	u.name not in ('PUBLIC')
union all
select	4 sort0, '' sort1, '' sort2, chr(10) txt from dual
union all
select	5 sort0,
	u.name sort1,
	l.name sort2,
	'drop procedure "'||u.name||'".delphix##_refresh##'||trim(to_char(row_number() over (partition by 5 order by u.name, l.name),'0000'))||';' txt
from	link$ l, user$ u
where	l.owner# = u.user#
and	u.name not in ('PUBLIC')
order by sort0, sort1, sort2;
prompt 
prompt spool off
exit success
__EOF1__
if (( $? != 0 ))
then
	echo "`date` SQL*Plus generating \"${_recreateDBLinkScript}.sql\" failed; aborting..."
	echo "Please review spooled output file \"${_outFile}\""
	exit 1
fi
#
#--------------------------------------------------------------------------------
# Run the "drop" and "recreate" scripts, then finally call the UTL_RECOMP package
# to recompile everything...
#--------------------------------------------------------------------------------
${ORACLE_HOME}/bin/sqlplus -L -S / as sysdba << __EOF2__ > ${_outFile} 2>&1
col right_now new_value V_RIGHT_NOW noprint
select to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS') right_now from dual;
prompt SYSDATE is &&V_RIGHT_NOW....
whenever oserror exit failure
whenever sqlerror exit failure
set echo off feedback off timing off pagesize 0 linesize 500 trimout on trimspool on
col sort0 noprint
col sort1 noprint
col sort2 noprint
col txt format a500
prompt
prompt Running generated script to recreate all database links...
prompt start ${_recreateDBLinkScript}
start ${_recreateDBLinkScript}
prompt 
prompt Recompiling all invalid objects as requested...
spool ${_reCompileOut}.lst
set echo on feedback on timing on trimout on trimspool on termout on
prompt ${_reCompileCmd}
${_reCompileCmd}
exit success
__EOF2__
if (( $? != 0 ))
then
	echo "`date` SQL*Plus running drop, recreate, and recompile scripts failed; aborting..."
	echo "Please review spooled output file \"${_outFile}\""
	exit 1
fi
#
#--------------------------------------------------------------------------------
# Clean up generated SQL*Plus scripts and spooled output files...
#--------------------------------------------------------------------------------
rm -f ${_outFile} 
rm -f ${_recreateDBLinkScript}*
rm -f ${_reCompileOut}*
#
#--------------------------------------------------------------------------------
# Completed successfully...
#--------------------------------------------------------------------------------
exit 0
