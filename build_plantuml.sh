#!/bin/bash
#
# Build Plantuml

echo "$0 started at $(date)"

CURRENT_PATH=$(pwd)
BUILD_PATH="${BUILD_PATH:-$CURRENT_PATH/build}"

set -euo pipefail

mkdir -p ${BUILD_PATH}

GRAPHVIZ_VERSION="${GRAPHVIZ_VERSION:-2.44.0}"
JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
export JAVA_HOME

${JAVA_HOME}/bin/java --version

rm -Rf ${BUILD_PATH}/plantuml
cd ${BUILD_PATH}
git clone https://github.com/plantuml/plantuml.git

cd ${BUILD_PATH}/plantuml
gradle build
rm ${BUILD_PATH}/plantuml/build/libs/plantuml*javadoc.jar
rm ${BUILD_PATH}/plantuml/build/libs/plantuml*sources.jar
cp ${BUILD_PATH}/plantuml/build/libs/plantuml*.jar ${BUILD_PATH}/plantuml.jar

rm -Rf ${BUILD_PATH}/jlatexmath
cd ${BUILD_PATH}
git clone https://github.com/plantuml/jlatexmath.git
cd ${BUILD_PATH}/jlatexmath
mvn package -Dmaven.test.skip=true -Djava.version=1.8
cp ./jlatexmath/target/jlatexmath-*-SNAPSHOT.jar ${BUILD_PATH}/jlatexmath.jar

#curl -o ${BUILD_PATH}/batik-svg-dom.jar https://repo1.maven.org/maven2/org/apache/xmlgraphics/batik-svg-dom/1.14/batik-svg-dom-1.14.jar
#curl -o ${BUILD_PATH}/batik-dom.jar https://repo1.maven.org/maven2/org/apache/xmlgraphics/batik-dom/1.14/batik-dom-1.14.jar
#curl -o ${BUILD_PATH}/batik-i18n.jar https://repo1.maven.org/maven2/org/apache/xmlgraphics/batik-i18n/1.14/batik-i18n-1.14.jar
curl -o ${BUILD_PATH}/batik-all.jar https://repo1.maven.org/maven2/org/apache/xmlgraphics/batik-all/1.14/batik-all-1.14.jar

cd ${CURRENT_PATH}

echo "$0 finished successfully at $(date)"

exit 0
