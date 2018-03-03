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
# Program Name : dxh_hook_functions.sh
# Description  : Hook Template functions
# Author       : Edward de los Santos
# Created      : 2018.01.28
#

BASEDIR=$(dirname $0)
PROGNAME=$(basename $0)

log_echo() {
   LOG_DTE=`date '+%Y-%m-%d %H:%M:%S' | tr -d '\n'`
   echo "${LOG_DTE} [INFO]  ${1}" 
   echo "${LOG_DTE} [INFO]  ${1}" >> ${LOGFILE}
}

error_echo() {
   LOG_DTE=`date '+%Y-%m-%d %H:%M:%S' | tr -d '\n'`
   echo "${LOG_DTE} [ERROR] ${1}"
   echo "${LOG_DTE} [ERROR] ${1}" >> ${LOGFILE}
}

debug_echo() {
   if [ ${DEBUG} -gt 0 ]; then
       LOG_DTE=`date '+%Y-%m-%d %H:%M:%S' | tr -d '\n'`
       echo "${LOG_DTE} [DEBUG] ${1}" 
       echo "${LOG_DTE} [DEBUG] ${1}" >> ${LOGFILE}
   fi
}

check_dir_exists() {
   debug_echo "entering :::check_dir_exists():::"
   DIRECTORY_NAME=${1}
   if [ ! -d ${DIRECTORY_NAME} ]; then
      error_echo "Error: Directory ${DIRECTORY_NAME} does not exist!"
      exit 1
   fi
}

check_file_exists() {
   debug_echo "entering :::check_file_exists():::"
   filename=${1}
   if [ ! -r ${filename} ]; then
      error_echo "File ${filename} does not exist!"
      exit 1
   fi
}

#exec_sqlplus_script() {
#sqlscript=${1}
#debug_echo "entering :::exec_sqlplus_script:::"
#   sqlout=`${ORACLE_HOME}/bin/sqlplus -s / as sysdba << EOF 
#@${sqlscript}
#EOF`
#   debug_echo "${sqlout}"
#   errcode=`echo "${sqlout}" | grep -c "ORA-"`
#   return "${errcode}"
#}
#

exec_sqlplus_script() {
sqlscript=${1}
SERVICE_NAME=${2}
USERNAME=${3}
PASSWORD=${4}
CONN=""

    if [ -z ${SERVICE_NAME} ]; then
        CONN=""
    else
        CONN="conn ${USERNAME}/${PASSWORD}@${SERVICE_NAME}"
    fi

    debug_echo "entering :::exec_sqlplus_script:::"
    debug_echo "executing ${sqlscript}"
   sqlout=`${ORACLE_HOME}/bin/sqlplus -s / as sysdba << EOF 
${CONN}
@${sqlscript}
EOF`
   debug_echo "${sqlout}"
   errcode=`echo "${sqlout}" | grep -c "ORA-"`
   return "${errcode}"
}

exec_sqlplus_check() {
sqlscript=${1}
SERVICE_NAME=${2}
USERNAME=${3}
PASSWORD=${4}
CONN=""
sqlcmd="select sysdate from dual;"

    if [ -z ${CONN} ]; then
        CONN=""
    else
        CONN="conn ${USERNAME}/${PASSWORD}@${SERVICE_NAME}"
    fi

   debug_echo "entering :::exec_sqlplus_script:::"
   sqlout=`${ORACLE_HOME}/bin/sqlplus -s / as sysdba << EOF 
${CONN}
@${sqlcmd}
EOF`
   debug_echo "${sqlout}"
   errcode=`echo "${sqlout}" | grep -c "ORA-"`
   return "${errcode}"
}

exec_sqlplus_sql() {
debug_echo "entering :::exec_sqlplus_sql:::"
sqlcmd="${1}"
   debug_echo "${sqlcmd}"
   sqlout=`${ORACLE_HOME}/bin/sqlplus -s / as sysdba << EOF 
set head off feed off veri off
${sqlcmd}
EOF`
   DBNAME=$(echo "${sqlout}" | tr -d '\n')
   errcode=`echo "${sqlout}" | grep -c "ORA-"`
   return "${errcode}"
}

exec_sqlplus_get_dbname() {
sqlcmd="select name from v\$database;"
   sqlout=`${ORACLE_HOME}/bin/sqlplus -s / as sysdba << EOF 
set head off feed off veri off
${sqlcmd}
EOF`
   DBNAME=$(echo "${sqlout}" | tr -d '\n')
   errcode=`echo "${sqlout}" | grep -c "ORA-"`
   return "${errcode}"
}

mail_attachment () {
debug_echo "entering :::mail_attachment():::"
subject=$1
raddr=$2
to=$3
attach=$4
battach=`basename ${attach} | tr -d '\n'`
uuencode ${attach} ${battach} | mailx  -r "${raddr}" -s "${subject}" "${to}"
}

mail_text () {
debug_echo "entering :::mail_text():::"
subject=$1
raddr=$2
to=$3
body=$4
mailx  -r "${raddr}" -s "${subject}" "${to}" << EOF
${body}
EOF
}






  

