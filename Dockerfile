FROM ubuntu:jammy-20220531

LABEL maintener emmanuel.guisse@egitc.com
LABEL description="This image provides converter from markdown to pdf"
LABEL project-name="mddoc"
LABEL project_url="https://github.com/eguisse/mddoc"
LABEL version="$VERSION"

ENV DEBIAN_FRONTEND=noninteractive
RUN useradd --uid 1000 -m -s /bin/bash build
RUN apt-get update -q \
  && apt-get install -q -y software-properties-common locales pandoc gettext-base xz-utils \
  exiftool vim openjdk-17-jdk python3 python3-pip python3-venv git curl wget lftp \
  ca-certificates  fontconfig ttf-mscorefonts-installer fonts-ipafont xfonts-efont-unicode fonts-freefont-otf \
  libxext6 libxrender1 xfonts-75dpi xfonts-base zlib1g libpng-tools graphviz lua5.3 \
  librsvg2-common librsvg2-doc libpangocairo-1.0-0 libgtk-3-0 libjlatexmath-java \
  libjs-mathjax librsvg2-bin python3-m2r pandoc-plantuml-filter pandoc-citeproc ocaml pandoc-data \
  wkhtmltopdf pandoc-citeproc-preamble fonts-freefont-ttf
#  nodejs groff ghc context zlib1g pandoc-data libgmp10 libgmp10-dev libatomic1 libpcre3 texlive-xetex


RUN rm -rf /var/lib/apt/lists/* \
  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8


WORKDIR /srv

# add python requirements
COPY requirements.txt /srv/requirements.txt
RUN pip3 install -r /srv/requirements.txt
#RUN pip3 install wheel && pip3 install -r /srv/requirements.txt
COPY src/ /srv/


# install plantuml
RUN /bin/bash -c 'cp /srv/plantuml /usr/local/bin/plantuml \
  && chmod a+rx /usr/local/bin/plantuml \
  && mkdir -p /opt/plantuml \
  && chmod a+rx /opt/plantuml'
COPY build/plantuml.jar /opt/plantuml/plantuml.jar
COPY build/jlatexmath.jar /opt/plantuml/jlatexmath.jar
COPY build/batik-all.jar /opt/plantuml/batik-all.jar
RUN /bin/bash -c 'chmod a+r /opt/plantuml/plantuml.jar'


RUN chmod 777 /srv
WORKDIR /srv

RUN /bin/bash -c 'chmod a+wx *.sh'


# Copy VERSION file
COPY VERSION /srv/VERSION

USER build
WORKDIR /mnt
RUN mkdir -p /home/build/.local/share/pandoc

ENV PYTHONPATH=/srv
ENV MDDOC_RUNTIME_PATH=/srv
ENV MDDOC_WORKDIR=/mnt
ENV PATH=/srv:/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PLANTUML_BIN=/usr/local/bin/plantuml

CMD /bin/bash

