#
# Dockerfile for creating an ubuntu machine with MLKit and SMLtoJs
# installed.
#
# Build it with:
#
#  docker build -t oml .
#
# Run the image with:
#
#  docker run -it oml
#

FROM --platform=linux/amd64 ubuntu:20.04
WORKDIR /opt/oml

RUN apt-get update && apt-get install -y \
    gcc autoconf make

ADD https://github.com/melsman/mlkit/releases/latest/download/mlkit-bin-dist-linux.tgz .

RUN tar xzf mlkit-bin-dist-linux.tgz

RUN cd ./mlkit-bin-dist-linux && make install

RUN mkdir /usr/local/etc/mlkit && \
    mkdir /usr/local/etc/smltojs && \
    echo "SML_LIB /usr/local/lib/mlkit" > /usr/local/etc/mlkit/mlb-path-map && \
    echo "SML_LIB /usr/local/lib/smltojs" > /usr/local/etc/smltojs/mlb-path-map

RUN cd ..

RUN rm -rf ./mlkit-bin-dist-linux.tgz ./mlkit-bin-dist-linux

COPY . .

RUN ./autobuild
RUN ./configure --with-compiler=mlkit
RUN make mlkit