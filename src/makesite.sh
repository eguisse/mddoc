#!/bin/bash
#
# Markdown to readthedoc web site
#
# Copyright (c) 2019 2020, Emmanuel GUISSE
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

set -x

# global parameters
CURRENT_DIR="$(pwd)"
MDDOC_WORKDIR="${MDDOC_WORKDIR:-CURRENT_DIR}"

declare -gx _BUILD_DIR="${MDDOC_WORKDIR}/build"

set -uo pipefail


mkdir -p "${_BUILD_DIR}"

touch "${_BUILD_DIR}/touchfile.txt"

python3 ${MDDOC_RUNTIME_PATH}/makepdf.py $@
retcode=$?
if [[ $retcode -ne 0 ]]
then
  exit $retcode
fi

set -euo pipefail

if [[ ! -f "/tmp/combined.env" ]]
then
    echo "ERROR file not found: /tmp/combined.env"
    exit 1
fi

source /tmp/combined.env

mkdir -p "${_SITE_PATH}"

mkdocs build -v -c -f ${_MKDOCS_CONFIG_FILENAME} -d ${_SITE_PATH} --no-directory-urls

if [[ $? -ne 0 ]]
then
  echo "ERROR: mkdocs finished with error" >&2
  exit 1
fi

echo "$0 finished successfully at $(date)"

exit 0
