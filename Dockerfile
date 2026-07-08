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
    python3.12 pipx python3.12-venv git curl vim wget gnupg \
    ca-certificates  fontconfig ttf-mscorefonts-installer fonts-ipafont xfonts-efont-unicode fonts-freefont-otf \
    ttf-wqy-microhei zlib1g libpng-tools fonts-freefont-ttf locales plantuml exiftool pandoc exiftool \
    openjdk-25-jre bash gettext-base zlib1g-dev libpng-tools libjpeg9-dev build-essential graphviz \
    libpython3-dev pandoc-data pandoc-sidenote ocaml xfonts-75dpi xfonts-base fonts-recommended wkhtmltopdf \
    nodejs npm
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -q -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1

# clean apt repo and setup locales
RUN rm -rf /var/lib/apt/lists/* \
  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8




# Copy VERSION file
RUN echo "$VERSION" > /srv/VERSION
ARG COMMIT_SHA="unknown"
RUN echo "$COMMIT_SHA" > /srv/COMMIT

# install plantuml
COPY src/plantuml /usr/local/bin/plantuml
ADD https://github.com/plantuml/plantuml/releases/download/v1.2026.6/plantuml-1.2026.6.jar /opt/plantuml/plantuml.jar
ADD https://repo1.maven.org/maven2/org/scilab/forge/jlatexmath/1.0.7/jlatexmath-1.0.7.jar /opt/plantuml/jlatexmath.jar
ADD https://repo1.maven.org/maven2/org/apache/xmlgraphics/batik-all/1.19/batik-all-1.19.jar /opt/plantuml/batik-all.jar

RUN mkdir -p /opt/plantuml && \
    chmod a+rwx /opt/plantuml && \
    chmod a+r /opt/plantuml/* && \
    chmod a+x /usr/local/bin/plantuml

# Install mermaid cli
RUN npm install -g @mermaid-js/mermaid-cli
# install puppeteer
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome
RUN npm install -g puppeteer
RUN groupadd pptruser && useradd -m -s /bin/bash -g pptruser pptruser \
    && mkdir -p /home/pptruser/Downloads \
    && chown -R pptruser:pptruser /home/pptruser \
    && usermod -a -G pptruser ubuntu

COPY src/ /srv/
RUN chmod 777 /srv && chmod a+wx /srv/*.sh
WORKDIR /srv

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
ENV JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64
ENV PLANTUML_BIN=/usr/local/bin/plantuml

CMD [ "/bin/bash" ]

