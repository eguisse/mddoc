#!/bin/bash
#
# Markdown to MS doc converter
#
# Copyright (c) 2019 2020, EGITC and/or its affiliates. All rights reserved.
#
set -x

# global parameters
CURRENT_DIR="$(pwd)"
MDDOC_WORKDIR="${MDDOC_WORKDIR:-CURRENT_DIR}"

declare -gx _BUILD_PATH="${MDDOC_WORKDIR}/build"
#declare -gx _MKDOC_CONFIG="mkdocs.yml"
declare -gx _TITLE=""
declare -gx _AUTHOR=""
declare -gx _STATUS=""
declare -gx _DATE=""
declare -gx _VERSION=""
declare -gx _RIGHTS=""
declare -gx _RUNTIME_PATH=""
declare -gx _SOURCE_URL=""
declare -gx _FILENAME=""
declare -gx _PROJECTNAME=""
declare -gx _GIT_VERSION=""
declare -gx _GIT_DATE=""
declare -gx _GIT_REPONAME=""
declare -gx _CONFIDENTIALITY=""
declare -gx _PDFOUTFILE="report.pdf"
declare -gx _RESOURCE_PATH=""
declare -gx _WKHTMLTOPDF_OPTS="--dpi 300 --print-media-type --minimum-font-size 2 -B 25mm -L 10mm -R 5mm -T 25mm -O Portrait -s A4 --page-size A4 "
declare -gx _DOC_PATH=""
declare -gx _COMPANY_NAME=""
declare -gx _COMPANY_URL=""

export XDG_RUNTIME_DIR=/tmp/runtime-$$
export DEBUG=1
mkdir -p ${XDG_RUNTIME_DIR}
chmod 700 ${XDG_RUNTIME_DIR}

echo "$0 started at `date`"

set -euo pipefail

echo "test internet access"
curl -o /tmp/Archimate.puml "https://raw.githubusercontent.com/ebbypeter/Archimate-PlantUML/master/Archimate.puml"


python3 ${MDDOC_RUNTIME_PATH}/makepdf.py $@

if [[ $? -ne 0 ]]
then
  echo "ERROR: combine: makepdf.py finished with error" >&2
  exit 1
fi

if [[ ! -f "${_BUILD_PATH}/combined.env" ]]
then
    echo "ERROR file not found: ${_BUILD_PATH}/combined.env"
    exit 1
fi

source ${_BUILD_PATH}/combined.env

if [[ ! -f "${_PDF_PAGE1_HTML}" ]]
then
    echo "ERROR file not found: ${_PDF_PAGE1_HTML}"
    exit 1
fi



# Convert combined markdown file to single html5
#
# pandoc template: https://github.com/jgm/pandoc-templates
#


envsubst "`printf '${%s} ' $(env|cut -d'=' -f1)`" < "${_PDF_PAGE1_HTML}" > "${_BUILD_PATH}/pdf-page1.html"
CURRENT_DIR="$(pwd)"
mkdir -p /tmp/pandoc
cd /tmp/pandoc
#-f markdown+smart \
#--columns=60 \
#--css="${_CSS_FILE}" \

pandoc "${_BUILD_PATH}/combined.md" \
--verbose \
--log="${_BUILD_PATH}/pandoc.log" \
--self-contained \
--resource-path "${_BUILD_PATH}:${_DOC_PATH}:/tmp/pandoc" \
-f gfm+smart \
-t docx \
-s -o "${_PDFOUTFILE}.docx" \
--template "${_TEMPLATE_HTML}" \
--lua-filter="${_RESOURCE_PATH}/links-to-html.lua" \
--filter pandoc-plantuml \
--highlight-style espresso \
--columns=80 \
--css="${_CSS_FILE}" \
--include-before-body="${_BUILD_PATH}/pdf-page1.html"

if [ $? -ne 0 ]
then
  echo "ERROR: pandoc finished with error" >&2
  exit 1
fi



echo "$0 finished successfully at $(date)"

exit 0
