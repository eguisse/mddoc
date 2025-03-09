FROM ubuntu:24.04

LABEL org.opencontainers.image.authors="emmanuel.guisse@egitc.com"
LABEL org.opencontainers.image.description="This image provides converter from markdown to pdf"
LABEL org.opencontainers.image.ref.name="mddoc"
LABEL org.opencontainers.image.url="https://github.com/eguisse/mddoc"
LABEL org.opencontainers.image.source="https://github.com/eguisse/mddoc"
ARG VERSION
LABEL org.opencontainers.image.version="$VERSION"


ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -q \
  && apt-get install -q -y \
    python3 pipx python3-venv git curl vim \
    ca-certificates  fontconfig ttf-mscorefonts-installer fonts-ipafont xfonts-efont-unicode fonts-freefont-otf \
    zlib1g libpng-tools fonts-freefont-ttf locales plantuml exiftool pandoc-plantuml-filter pandoc exiftool \
    openjdk-21-jre bash git gettext-base zlib1g-dev libpng-tools libjpeg9-dev build-essential \
    libpython3-dev pandoc-data pandoc-sidenote ocaml xfonts-75dpi xfonts-base

# clean apt repo and setup locales
RUN rm -rf /var/lib/apt/lists/* \
  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# install wkhtmltox with patched qt
ENV WKHTMLTOPDF_VERSION="0.12.6.1-3"
RUN /bin/bash -c 'wget --quiet --output-document=/tmp/wkhtmltox.jammy_amd64.deb https://github.com/wkhtmltopdf/packaging/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox_${WKHTMLTOPDF_VERSION}.jammy_amd64.deb && \
    dpkg -i /tmp/wkhtmltox.jammy_amd64.deb && \
    rm /tmp/wkhtmltox.jammy_amd64.deb'


# add python requirements
COPY src/ /srv/
RUN chmod 777 /srv
WORKDIR /srv
# Copy VERSION file
RUN echo "$VERSION" > /srv/VERSION
ARG COMMIT_SHA="unknown"
RUN echo "$COMMIT_SHA" > /srv/COMMIT

# install plantuml
COPY src/plantuml /usr/local/bin/plantuml
ADD https://github.com/plantuml/plantuml/releases/download/v1.2025.2/plantuml-1.2025.2.jar /opt/plantuml/plantuml.jar
ADD https://repo1.maven.org/maven2/org/scilab/forge/jlatexmath/1.0.7/jlatexmath-1.0.7.jar /opt/plantuml/jlatexmath.jar
ADD https://repo1.maven.org/maven2/org/apache/xmlgraphics/batik-all/1.14/batik-all-1.14.jar /opt/plantuml/batik-all.jar

RUN mkdir -p /opt/plantuml && \
    chmod a+rwx /opt/plantuml && \
    chmod a+r /opt/plantuml/* && \
    chmod a+wx /srv/*.sh && \
    chmod a+x /usr/local/bin/plantuml

USER ubuntu

ENV LANG=en_US.utf8
ENV PATH=/home/ubuntu/venv/bin:/srv:/home/ubuntu/.local/bin:/usr/local/bin:/usr/bin:/sbin:/bin
COPY requirements.txt /srv/requirements.txt
# install python requirements
RUN python3 -m venv /home/ubuntu/venv && \
    . /home/ubuntu/venv/bin/activate && \
    pip3 install --upgrade pip && \
    pip3 install wheel setuptools && \
    pip3 install -r /srv/requirements.txt && \
    git config --global --add safe.directory '*'

#
ENV PYTHONPATH=/srv
ENV MDDOC_RUNTIME_PATH=/srv
ENV MDDOC_WORKDIR=/mnt
ENV PLANTUML_BIN=/usr/local/bin/plantuml



WORKDIR /mnt
RUN mkdir -p /home/ubuntu/.local/share/pandoc \
    && git config --global safe.directory '*'

ENV PYTHONPATH=/srv
ENV MDDOC_RUNTIME_PATH=/srv
ENV MDDOC_WORKDIR=/mnt
#ENV PATH=/home/ubuntu/venv/bin:/srv:/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV PLANTUML_BIN=/usr/local/bin/plantuml

CMD [ "/bin/bash" ]

