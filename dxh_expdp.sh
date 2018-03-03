#!/bin/sh 
#
# Copyright (c) 2017, 2018 by Delphix. All rights reserved.
#
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright (c) 2015,2016,2017,2018 by Delphix. All rights reserved.
#
# Program Name : dxh_expdp.sh
# Description  : Delphix Oracle expdp wrapper script
# Author       : Edward de los Santos
# Created      : 2018.01.28
#

BASEDIR=$(dirname $0)
PROGNAME=$(basename $0)
DBNAME=""
dte=`date '+%Y%m%d' | tr -d '\n'`
OPERATION="config-clone|pre-refresh|post-refresh|pre-snapshot|post-snapshot|pre-rewind|post-rewind|pre-start|post-stop"

. ${BASEDIR}/dxh_hook_profile.sh
. ${BASEDIR}/dxh_hook_functions.sh


usage() {
   echo
   echo "Usage: $0 -o <hook_operation> -d <dump directory>  -p <parfile>"
   echo "Where: "
   echo "  -o ${OPERATION}"
   echo "  -d Dump directory"
   echo "  -p expdp parameter file. "
   echo "     Parameter file should be in dxhooks/<DBNAME>/<hook-operation>/parfile directory"
   echo
   exit 1
}
   

####################################
# Main Program
####################################

for i in $*
do
   case $1 in
      -o) hook_op=$2; shift 2;;
      -d) datapump_dir=$2; shift 2;;
      -p) parfile=$2; shift 2;;
      -*) usage; exit 1;;
   esac
done

if [ -z "${parfile}" ] && [ -z "${hook_op}" ]; then
   usage
   exit 1
fi

if [ $(echo ${hook_op} | egrep -c ${OPERATION}) -eq 0 ]; then
   usage
   exit 1
fi

if [ -z "${PARFILE_DIR}/${parfile}" ]; then
   error_echo "Can't open ${PARFILE_DIR}/${parfile} file"
   exit 1
fi

# ORACLE_HOME is set when script is configure in Delphix post hook operation
if [ -z ${ORACLE_HOME} ] &&  [ -z ${ORACLE_SID} ]; then
    echo "Error: ORACLE_HOME and ORACLE_SID variable not set."
    echo "       Make sure to configure the ${ORACLE_HOME} when running the script outside of Delphix post hook operation!"
    exit 1
fi
exec_sqlplus_get_dbname
RETCODE=$?
if [[ ${RETCODE} -gt 0 ]]; then
    echo "Error: Failed to execute the query. Please check if the instance is UP or ORACLE_SID is correct."
    exit 1
fi

PARFILE_DIR="${BASEDIR}/${DBNAME}/${hook_op}/parfile"
LOGDIR="${BASEDIR}/${DBNAME}/logs"
LOGFILE="${LOGDIR}/${PROGNAME}.${hook_op}.log"
export PARFILE_DIR LOGDIR LOGFILE

log_echo "${PROGNAME} execution started"

# Check if directories exists
check_dir_exists "${PARFILE_DIR}"
check_dir_exists "${LOGDIR}"
check_dir_exists "${datapump_dir}"
check_file_exists "${PARFILE_DIR}/${parfile}"
dxh_datapump="dxh_datapump_dir_$$"

sqlcmd="create or replace directory ${dxh_datapump} as '${datapump_dir}';"
debug_echo "${sqlcmd}"
exec_sqlplus_sql  "${sqlcmd}"
[ $? -gt 0 ] && error_echo "command execution failed." 

log_echo "executing ${ORACLE_HOME}/bin/expdp \"'/ as sysdba'\" parfile=\"${PARFILE_DIR}/${parfile}\" directory=\"${dxh_datapump}\""

${ORACLE_HOME}/bin/expdp "'/ as sysdba'" parfile="${PARFILE_DIR}/${parfile}" directory="${dxh_datapump}" 

# drop up datadump directory
sqlcmd="drop directory ${dxh_datapump};"
exec_sqlplus_sql  "${sqlcmd}"
[ $? -gt 0 ] && error_echo "command execution failed." 

log_echo "${PROGNAME} execution completed"

exit 0




