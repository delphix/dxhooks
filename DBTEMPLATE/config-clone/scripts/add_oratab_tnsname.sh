#!/bin/bash
#================================================================================
# File:		add_oratab_tnsname.sh
# Type:		korn-shell script
# Author:       Delphix field services
# Date:		30-October 2015
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
#       Copyright (c) 2015 by Delphix.  All rights reserved.
#
# Ownership and responsibility:
#
#       This script is offered without warranty by Delphix Field Services.
#       Anyone using this script accepts full responsibility for use, effect,
#       and maintenance.  Please do not contact Delphix support unless there
#	is a problem with a supported Delphix component used in this script,
#	such as the Delphxi CLI or the Delphix REST API.
#
# Description:
#
#	Shell-script intended to be called from a Delphix "ConfigureClone" hook
#	to automatically add an ORATAB entry and a  TNSNAMES entry corresponding
#	to the $ORACLE_SID and $ORACLE_HOME values for a VDB.
#
#	If the script detects that these values already exist in these configuration
#	files, then the script does nothing.
#
#	If there is no existing ORATAB or TNSNAMES entry for the ORACLE_SID and
#	ORACLE_HOME values, then the script will append appropriate values to the
#	appropriate file.
#
# Command-line parameters:
#
#	TNS-listener-port	(optional) TNS port number, if left blank then
#				use default value of 1521
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
#	TGorman	30oct15	first version
#	TGorman 15may17 added ORATAB functionality, made TNSNAMES optional
#================================================================================
#
_progName=add_oratab_tnsname
#--------------------------------------------------------------------------------
# Validate the command-line parameter...
#--------------------------------------------------------------------------------
if (( $# > 1 ))
then
	echo "Usage: \"${_progName}.sh [ <TNS-Listener-port> ]\"; aborting..."
	exit 1
fi
#
#--------------------------------------------------------------------------------
# If a port number was not specified, then use the default TNS port 1521...
#--------------------------------------------------------------------------------
if (( $# == 1 ))
then
	typeset -i _portNbr=${1}
	if (( ${_portNbr} < 1024 || ${_portNbr} > 65535 ))
	then
		echo "Usage: \"${_progName}.sh <TNS-Listener-port>\"; aborting..."
		echo "<TNS-Listener-port> \"${_portNbr}\" not between 1024 and 65535; aborting..."
		exit 1
	fi
else
	typeset -i _portNbr=1521
fi
#
#--------------------------------------------------------------------------------
# Validate the environmental inputs, ORACLE_SID and ORACLE_HOME...
#--------------------------------------------------------------------------------
if [[ "${ORACLE_SID}" = "" ]]
then
	echo "ORACLE_SID not set; aborting..."
	exit 1
fi
_output=`ps -eaf | grep ora_pmon_${ORACLE_SID} | grep -v grep`
if [[ "${_output}" = "" ]]
then
	echo "No VDB running for ORACLE_SID \"${ORACLE_SID}\"; aborting..."
	exit 1
fi
if [[ "${ORACLE_HOME}" = "" ]]
then
	echo "ORACLE_HOME not set; aborting..."
exit 1
fi
if [ ! -d ${ORACLE_HOME} ]
then
	echo "ORACLE_HOME directory (\"${ORACLE_HOME}\") not accessible; aborting..."
	exit 1
fi
if [ ! -d ${ORACLE_HOME}/bin ]
then
	echo "ORACLE_HOME directory (\"${ORACLE_HOME}/bin\") not accessible; aborting..."
	exit 1
fi
if [ ! -x ${ORACLE_HOME}/bin/tnsping ]
then
	echo "Executable (\"${ORACLE_HOME}/bin/tnsping\") not executable; aborting..."
	exit 1
fi
if [ ! -d ${ORACLE_HOME}/network ]
then
	echo "ORACLE_HOME directory (\"${ORACLE_HOME}/network\") not accessible; aborting..."
	exit 1
fi
if [ ! -d ${ORACLE_HOME}/network/admin ]
then
	echo "ORACLE_HOME directory \"${ORACLE_HOME}/network/admin\" not accessible; aborting..."
	exit 1
fi
if [[ "${TNS_ADMIN}" = "" ]]
then
	export TNS_ADMIN=${ORACLE_HOME}/network/admin
fi
if [ ! -d ${TNS_ADMIN} ]
then
	echo "TNS_ADMIN directory \"${TNS_ADMIN}\" not accessible; aborting..."
	exit 1
fi
#
#--------------------------------------------------------------------------------
# Determine location of "oratab" file based on OS platform...
#--------------------------------------------------------------------------------
case "`uname`" in
	Linux)	_oraTabFile="/etc/oratab"
		;;
	SunOS)	_oraTabFile="/var/opt/oracle/oratab"
		;;
	*)	echo "OS platform \"`uname`\" not yet supported by this script; aborting..."
		exit 1
		;;
esac
#
#--------------------------------------------------------------------------------
# Verify whether an ORATAB file exists or not...
#--------------------------------------------------------------------------------
typeset -i _exitStatus=0
if [ -f ${_oraTabFile} ]
then
	#
	#------------------------------------------------------------------------
	# Verify whether an ORACLE_SID entry for this ORACLE_HOME already exists
	# or not...
	#------------------------------------------------------------------------
	grep "^${ORACLE_SID}:${ORACLE_HOME}:" ${_oraTabFile} > /dev/null 2>&1
	if (( $? == 0 ))
	then
		echo "\"${_oraTabFile}\" already has an entry for ORACLE_SID=\"${ORACLE_SID}\", ORACLE_HOME=\"${ORACLE_HOME}\""
	else
		echo "${ORACLE_SID}:${ORACLE_HOME}:N" >> ${_oraTabFile}
		if (( $? != 0 )) 
		then
			echo "Writing \"${_oraTabFile}\" entry for ORACLE_SID=\"${ORACLE_SID}\", ORACLE_HOME=\"${ORACLE_HOME}\" failed"
			typeset -i _exitStatus=1
		fi
	fi
else	# ...create the ORATAB file if it doesn't yet exist...
	#
	echo "# Created by \"${_progName}.sh script on `date`..." > ${_oraTabFile}
	if (( $? != 0 ))
	then
		echo "Creating \"${_oraTabFile}\" file for ORACLE_SID=\"${ORACLE_SID}\", ORACLE_HOME=\"${ORACLE_HOME}\" failed""
		typeset -i _exitStatus=1
	fi
	echo "${ORACLE_SID}:${ORACLE_HOME}:N" >> ${_oraTabFile}
	if (( $? != 0 ))
	then
		echo "Writing \"${_oraTabFile}\" entry for ORACLE_SID=\"${ORACLE_SID}\", ORACLE_HOME=\"${ORACLE_HOME}\" failed""
		typeset -i _exitStatus=1
	fi
fi
#
#------------------------------------------------------------------------
# Verify whether a TNSNAMES entry for $ORACLE_SID already exists...
#------------------------------------------------------------------------
_tmpFile=/tmp/${_progName}_$$.tmp
${ORACLE_HOME}/bin/tnsping ${ORACLE_SID} > ${_tmpFile} 2>&1
grep "^Used TNSNAMES adapter to resolve the alias" ${_tmpFile} > /dev/null 2>&1
if (( $? == 0 ))
then
	grep "^OK " ${_tmpFile} > /dev/null 2>&1
	if (( $? == 0 ))
	then
		echo "TNS entry for ORACLE_SID \"${ORACLE_SID}\" already exists; no further action taken"
		rm -f ${_tmpFile}
		exit ${_exitStatus}
	fi
fi
rm -f ${_tmpFile}
#
#------------------------------------------------------------------------
# Verify that the "tnsnames.ora" configuration file exists and is writable...
#------------------------------------------------------------------------
if [ -f ${TNS_ADMIN}/tnsnames.ora ]
then
	if [ ! -w ${TNS_ADMIN}/tnsnames.ora ]
	then
		echo "TNSNAMES configuration file \"${TNS_ADMIN}/tnsnames.ora\" is not writable; aborting..."
		typeset -i _exitStatus=1
	fi
else
	echo "# tnsnames.ora: created `date` by Delphix Engine \"configure clone\" hook" > ${TNS_ADMIN}/tnsnames.ora
	if (( $? != 0 ))
	then
		echo "Unable to initialize empty file \"${TNS_ADMIN}/tnsnames.ora\"; aborting..."
		typeset -i _exitStatus=1
	else
		echo "#" >> ${TNS_ADMIN}/tnsnames.ora
	fi
fi
#
#------------------------------------------------------------------------
# Append a TNSNAMES entry for $ORACLE_SID to the "tnsnames.ora"
# configuration file...
#------------------------------------------------------------------------
if (( ${_exitStatus} == 0 ))
then
	_TnsAddr="(ADDRESS=(PROTOCOL=TCP)(HOST=`hostname`)(PORT=${_portNbr}))"
	_TnsConn="(CONNECT_DATA=(SID=${ORACLE_SID}))"
	_Comment=" # added by Delphix `date`"
	echo "" >> ${TNS_ADMIN}/tnsnames.ora
	echo "${ORACLE_SID}=(DESCRIPTION=${_TnsAddr}${_TnsConn})${_Comment}" >> ${TNS_ADMIN}/tnsnames.ora
	if (( $? != 0 ))
	then
		echo "Unable to append new TNSNAMES entry to \"${TNS_ADMIN}/tnsnames.ora\"; aborting..."
		typeset -i _exitStatus=1
	fi
fi
#
#--------------------------------------------------------------------------------
# Finished...
#--------------------------------------------------------------------------------
exit 0
