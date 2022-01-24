FROM ubuntu:impish

LABEL maintener emmanuel.guisse@egitc.com
LABEL description="This image provides converter from markdown to pdf"
LABEL project-name="mddoc"
LABEL project_url="https://github.com/eguisse/mddoc"


ENV DEBIAN_FRONTEND=noninteractive
RUN useradd --uid 1000 -m -s /bin/bash build
RUN apt-get update -q \
  && apt-get install -q -y software-properties-common locales pandoc gettext-base xz-utils \
  exiftool vim openjdk-16-jdk python3 python3-pip python3-venv git curl wget lftp \
  ca-certificates  fontconfig ttf-mscorefonts-installer ttf-ubuntu-font-family ttf-unifont fonts-ipafont \
  libxext6 libxrender1 xfonts-75dpi xfonts-base zlib1g libssl1.1 libpng-tools graphviz lua5.3 \
  librsvg2-common librsvg2-doc libpangocairo-1.0-0 libgtk-3-0 libjlatexmath-java \
  pandoc libjs-mathjax librsvg2-bin pandoc-citeproc ocaml pandoc-data
#  nodejs groff ghc context zlib1g pandoc-data libgmp10 libgmp10-dev libatomic1 libpcre3 texlive-xetex


RUN rm -rf /var/lib/apt/lists/* \
  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# add python requirements
COPY src/ /srv/
COPY requirements.txt /srv/
WORKDIR /srv
RUN pip3 install wheel && pip3 install -r /srv/requirements.txt

# Get Last version of pandoc
RUN chmod 777 /srv
WORKDIR /srv

ARG PANDOC_VERSION="2.17.0.1"
RUN /bin/bash -c 'wget --quiet "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz" \
    && tar -zxvf "/srv/pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz" \
    && ln -s "/srv/pandoc-${PANDOC_VERSION}/bin/pandoc" "/srv/pandoc" \
    && ln -s "/srv/pandoc-${PANDOC_VERSION}/bin/pandoc-citeproc" "/srv/pandoc-citeproc"'

#COPY build/wkhtmltox.focal_amd64.deb /opt/
#RUN dpkg -i /opt/wkhtmltox.focal_amd64.deb
#RUN /bin/bash -c 'curl --output /tmp/wkhtmltox.focal_amd64.deb http://storage.googleapis.com/engineering-doc-egitc-com/dist/wkhtmltox.focal_amd64.deb && \
#    dpkg -i /tmp/wkhtmltox.focal_amd64.deb && \
#    rm /tmp/wkhtmltox.focal_amd64.deb'

ARG WKHTMLTOPDF_VERSION="0.12.6-1"
RUN /bin/bash -c 'wget --quiet --output-document=/tmp/wkhtmltox.focal_amd64.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb && \
    dpkg -i /tmp/wkhtmltox.focal_amd64.deb && \
    rm /tmp/wkhtmltox.focal_amd64.deb'

RUN /bin/bash -c 'chmod a+wx *.sh'

# install plantuml
RUN /bin/bash -c 'cp /srv/plantuml /usr/local/bin/plantuml \
  && chmod a+rx /usr/local/bin/plantuml \
  && mkdir -p /opt/plantuml \
  && chmod a+rx /opt/plantuml'
COPY build/plantuml.jar /opt/plantuml/plantuml.jar
COPY build/jlatexmath.jar /opt/plantuml/jlatexmath.jar
RUN /bin/bash -c 'chmod a+r /opt/plantuml/plantuml.jar'


# Copy VERSION file
COPY VERSION /srv/VERSION

USER build
WORKDIR /mnt
ENV PYTHONPATH=/srv
ENV MDDOC_RUNTIME_PATH=/srv
ENV MDDOC_WORKDIR=/mnt
ENV PATH=/srv:/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV JAVA_HOME=/usr/lib/jvm/java-16-openjdk-amd64

CMD /bin/bash

