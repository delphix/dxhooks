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
# Copyright (c) 2015,2016 by Delphix. All rights reserved.
#
# Program Name : dxh_wrapper_script.sh
# Description  : Shell wrapper script for hook template
# Author       : Edward de los Santos
# Created      : 2018.01.28
#

BASEDIR=$(dirname $0)
PARENT_DIR=${1}
LOGFILE=${2}
DBNAME=${3}
HOOK_OP=${4}

. ${PARENT_DIR}/dxh_hook_profile.sh
. ${PARENT_DIR}/dxh_hook_functions.sh

#
######################
# code start here
######################
#

# sample code to initiate impdp
#/softwares/scripts/hooks/dxh_impdp.sh -o ${HOOK_OP} -d '/softwares/scripts/hooks/dumpdir' -p DBTEMPLATE.impdp.delphix.par 










