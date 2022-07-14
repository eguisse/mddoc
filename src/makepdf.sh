#!/bin/bash
#
# Markdown to pdf converter
#
# Copyright (c) 2018 - 2022, Emmanuel GUISSE
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
declare -gx _WKHTMLTOPDF_OPTS="--dpi 300 --minimum-font-size 2 -B 25mm -L 10mm -R 5mm -T 25mm -O Portrait -s A4 --page-size A4 --header-spacing 10 --footer-spacing 5 "
declare -gx _DOC_PATH=""
declare -gx _COMPANY_NAME=""
declare -gx _COMPANY_URL=""
declare -gx _PANDOC_OPTS="-f gfm+smart --filter pandoc-plantuml --highlight-style espresso --columns=80 --wrap=auto"
declare -gx _PDF_META_KEYWORDS=""
declare -gx _LOGO_FILENAME=""

export XDG_RUNTIME_DIR=/tmp/runtime-$$
export DEBUG=1
mkdir -p ${XDG_RUNTIME_DIR}
chmod 700 ${XDG_RUNTIME_DIR}

echo "$0 started at `date`"

set -euo pipefail

mkdir -p "${_BUILD_DIR}/site/images"

echo "test internet access"
curl -o /tmp/test.png "https://www.wikipedia.org/static/apple-touch/wikipedia.png"

echo ""
echo "merging md files..."
python3 ${MDDOC_RUNTIME_PATH}/makepdf.py $@

if [[ $? -ne 0 ]]
then
  echo "ERROR: combine: makepdf.py finished with error" >&2
  exit 1
fi

if [[ ! -f "/tmp/combined.env" ]]
then
    echo "ERROR file not found: /tmp/combined.env"
    exit 1
fi

source /tmp/combined.env

if [[ ! -f "${_PDF_PAGE1_HTML}" ]]
then
    echo "ERROR file not found: ${_PDF_PAGE1_HTML}"
    exit 1
fi



# Convert combined markdown file to single html5
#
# pandoc template: https://github.com/jgm/pandoc-templates
#


envsubst "`printf '${%s} ' $(env|cut -d'=' -f1)`" < "${_PDF_PAGE1_HTML}" > "${_BUILD_DIR}/pdf-page1.html"
CURRENT_DIR="$(pwd)"
mkdir -p /tmp/pandoc
cd /tmp/pandoc

# copy logo file
if [[ -f "${_LOGO_FILENAME}" ]]
then
    cp "${_LOGO_FILENAME}" "${_BUILD_DIR}/logo.png"
else
    if [[ -f "${_RESOURCE_PATH}/logo.png" ]]
    then
        cp "${_RESOURCE_PATH}/logo.png" "${_BUILD_DIR}/logo.png"
    fi
fi

envsubst "`printf '${%s} ' $(env|cut -d'=' -f1)`" \
  < "${_PDF_HEADER_HTML}" > "${_BUILD_DIR}/pdf-header.html"

envsubst "`printf '${%s} ' $(env|cut -d'=' -f1)`" \
  < "${_PDF_FOOTER_HTML}"> "${_BUILD_DIR}/pdf-footer.html"

echo ""
echo "start convert ùd tp html"
pandoc "${_BUILD_DIR}/combined.md" \
--verbose \
--log="${_BUILD_DIR}/pandoc.log" \
--self-contained \
--resource-path "${_BUILD_DIR}:${_DOC_PATH}:/tmp/pandoc" \
${_PANDOC_OPTS} \
-t html \
-s -o "${_BUILD_DIR}/combined.html" \
--template "${_TEMPLATE_HTML}" \
--lua-filter="${_RESOURCE_PATH}/links-to-html.lua" \
--css="${_CSS_FILE}" \
--include-before-body="${_BUILD_DIR}/pdf-page1.html"
#--metadata title="${_TITLE}"

if [ $? -ne 0 ]
then
  echo "ERROR: pandoc finished with error" >&2
  exit 1
fi
cd ${CURRENT_DIR}

if [[ ! -f "${_BUILD_DIR}/combined.html" ]]
then
  echo "ERROR: output file ${_BUILD_DIR}/combined.html not exists" >&2
  exit 1
fi

# Convert single html5 to pdf
#

echo ""
echo "start conv2pdf"

wkhtmltopdf \
    ${_WKHTMLTOPDF_OPTS} \
	--title "$_TITLE" \
	--header-line \
	--header-html "${_BUILD_DIR}/pdf-header.html" \
	--footer-line \
	--footer-html "${_BUILD_DIR}/pdf-footer.html" \
	--page-offset 0 \
	--enable-external-links \
	--enable-internal-links \
	--replace _COPYRIGHT "${_RIGHTS}" \
   "${_BUILD_DIR}/combined.html" \
   "${_BUILD_DIR}/combined.pdf"

if [[ $? -ne 0 ]]
then
  echo "ERROR: conv2pdf: wkhtmltopdf finished with error" >&2
  exit 1
fi

cp "${_BUILD_DIR}/combined.pdf" "${_PDFOUTFILE}"

echo "start exiftool"

exiftool \
	-overwrite_original_in_place \
	-rights="${_RIGHTS}" \
	-Title="${_TITLE}" \
	-Author="${_AUTHOR}" \
	-PDF:Author="${_AUTHOR}" \
	-keywords="${_PDF_META_KEYWORDS}" \
	-XMP-dc:Creator="${_AUTHOR}" \
	-XMP-dc:Source="$_SOURCE_URL" \
	-XMP-dc:Rights="${_RIGHTS}" \
	-XMP-dc:Language="en" \
	-XMP-dc:Title="${_TITLE}" \
	-XMP-dc:Subject="${_SUBJECT}" \
	-XMP-pdf:Author="${_AUTHOR}" \
	-XMP-pdf:Copyright="${_RIGHTS}" \
	-XMP-pdf:Title="${_TITLE}" \
	-XMP-pdf:Subject="${_SUBJECT}" \
	-XMP-xmpRights:Marked="True" \
	-XMP-xmpRights:Owner="${_OWNER}" \
	-XMP-xmpRights:WebStatement="${_RIGHTS}" \
	-Subject="${_SUBJECT}" \
	"${_PDFOUTFILE}"

if [[ $? -ne 0 ]]
then
	echo "ERROR: myexiftool: exiftool finished with error" >&2
	exit 1
fi


echo ""
echo "pdf output file is: ${_PDFOUTFILE}"

echo "$0 finished successfully at $(date)"

exit 0
