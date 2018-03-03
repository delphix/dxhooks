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
# Program Name : dxh_clonedb.sh
# Description  : Script to clone hook template db directory
# Author       : Edward de los Santos
# Created      : 2018.01.28
#

BASEDIR=$(dirname $0)
PROGNAME=$(basename $0)
DEBUG=0
dte=`date '+%Y%m%d' | tr -d '\n'`

. ${BASEDIR}/dxh_hook_profile.sh

usage() {
   echo
   echo "Usage: $0 -s <source dbname> -t <target dbname> [-f true|false(default) ]"
   echo "Where: "
   echo "  -s Source Database Name"
   echo "  -t Target Database Name"
   echo "  -f force copy (default is false)"
   echo
   exit 1
}
   

####################################
# Main Program
####################################

for i in $*
do
   case $1 in
      -s) src_dir=$2; shift 2;;
      -t) tgt_dir=$2; shift 2;;
      -f) force=$2; shift 2;;
      -*) usage; exit 1;;
   esac
done

if [ -z "${src_dir}" ] && [ -z "${tgt_dir}" ]; then
   usage
   exit 1
fi

[ -z "${force}" ] && force="false"

if [ ! -d "${src_dir}" ]; then
   echo "Error: Directory ${src_dir} does not exist."
fi

if [ ${force} = "true" ]; then
   echo
   echo "INFO: cloning directory ${src_dir} to ${tgt_dir}"
   echo
   cp -pr ${BASEDIR}/${src_dir} ${BASEDIR}/${tgt_dir}
else
   if [ -d "${tgt_dir}" ]; then
      echo
      echo "WARNING: directory ${tgt_dir} already exists." 
      echo
   else
      echo "INFO: cloning directory ${src_dir} to ${tgt_dir}"
      cp -pr ${BASEDIR}/${src_dir} ${BASEDIR}/${tgt_dir}
   fi
fi

exit 0






