#!/bin/bash
#
# Build Plantuml

echo "$0 started at $(date)"

CURRENT_PATH=$(pwd)
BUILD_PATH="${BUILD_PATH:-$CURRENT_PATH/build}"

set -euo pipefail

mkdir -p ${BUILD_PATH}

GRAPHVIZ_VERSION="${GRAPHVIZ_VERSION:-2.44.0}"

rm -Rf ${BUILD_PATH}/plantuml
cd ${BUILD_PATH}
git clone https://github.com/plantuml/plantuml.git

cd ${BUILD_PATH}/plantuml
ant dist
cp ${BUILD_PATH}/plantuml/plantuml.jar ${BUILD_PATH}/plantuml.jar

cd ${CURRENT_PATH}

echo "$0 finished successfully at $(date)"

exit 0
